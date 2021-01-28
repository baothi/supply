module ShopifyCache::Products::Variants
  extend ActiveSupport::Concern
  include CommitWrap

  included do
    # Split out Variants
    after_save :extract_variants!
    after_upsert :extract_variants!

    scope :has_not_yet_generated_variants, -> { where('last_generated_variants_at': nil) }
  end

  class_methods do
    def bulk_extract_missing_variants_for_all_suppliers!
      Spree::Supplier.installed.find_each do |supplier|
        create_and_run_extraction_job(supplier_id: supplier.id)
      end
    end

    def extract_missing_variants_for_supplier!(supplier)
      create_and_run_extraction_job(supplier_id: supplier.id)
    end

    def create_and_run_extraction_job(supplier_id:, async: true)
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          supplier_id: supplier_id
        )
        execute_after_commit do
          if async
            ::ShopifyCache::ExtractVariantsBySupplierJob.perform_later(job.internal_identifier)
          else
            ::ShopifyCache::ExtractVariantsBySupplierJob.new.perform(job.internal_identifier)
          end
        end
      end
    end
  end

  # Extract into ShopifyCache::Variant (different from ShopifyCache::ProductVariant)
  def extract_variants!
    self.variants.each do |variant|
      variant['lower_sku'] = variant.sku&.downcase
      variant['lower_barcode'] = variant.barcode&.downcase
      variant['shopify_url'] = self.shopify_url
      variant['role'] = self.role
      variant['product_id'] = self.id
      variant['product_published_at'] = self.published_at
      variant['product_deleted_at'] = self.deleted_at
      ShopifyCache::Variant.new(variant.as_json).upsert
    end
    # Done to avoid callbacks running again.
    self.set(last_generated_variants_at: DateTime.now)
  end
end
