module Spree::Products::SearchAttributable
  extend ActiveSupport::Concern

  included do
    before_save :build_search_attributes

    scope :with_no_search_attribute_timestamp, -> do
      where('spree_products.search_attributes_updated_at is null')
    end

    scope :with_search_attribute_last_updated_before, ->(datetime) do
      where('spree_products.search_attributes_updated_at < ? ', datetime)
    end

    # All
    scope :with_empty_search_criteria, -> do
      where('spree_products.search_attributes = ?', {}.to_json)
    end

    # Licenses
    scope :with_search_criteria_license_taxon_id, ->(taxon_id) do
      where("spree_products.search_attributes ->'license_taxons' @> ?", [{ "id": taxon_id.to_i }].to_json)
    end

    # Category
    scope :with_search_criteria_category_taxon_id, ->(taxon_id) do
      where("spree_products.search_attributes ->'category_taxons' @> ?", [{ "id": taxon_id.to_i }].to_json)
    end

    # Stock Quantity
    scope :with_search_criteria_stock_lte, ->(amount) do
      where("(spree_products.search_attributes->>'available_quantity')::int <= ?", amount)
    end

    scope :with_search_criteria_stock_gte, ->(amount) do
      where("(spree_products.search_attributes->>'available_quantity')::int >= ?", amount)
    end

    scope :with_search_criteria_eligible_for_intl_sale, -> do
      where('spree_products.search_attributes @> ?', { "eligible_for_international_sale": true }.to_json)
    end

    scope :with_search_criteria_exclude_discontinued, -> do
      where('spree_products.discontinue_on is null')
    end
  end

  class_methods do
    def build_search_attributes_for!(start_id:, end_id:)
      return unless start_id.present? && end_id.present?

      Spree::Product.find_each(start: start_id, finish: end_id) do |p|
        begin
          p.update_search_attributes!
        rescue => ex
          puts "#{ex}".red
          puts "We ran into an issue updating search attribute for #{p}"
          # TODO: Add Rollbar Notifier
        end
      end
    end

    def product_search_attribute_update_job(start, finish)
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        option_1: start,
        option_2: finish
      )
    end

    def build_search_attributes_for_all!(batch_size = 250, async = true)
      build_search_attributes_for_range!(1, Spree::Product.maximum(:id), batch_size, async)
    end

    # TODO: Refactor this bulk mechanism
    def build_search_attributes_for_range!(start, finish, batch_size = 250, async = true)
      ro = ResponseObject.blank_success_response_object
      begin
        raise 'Finish must be larger than start value' if start > finish

        num_batches = ((finish - start) / batch_size.to_f).ceil
        num_batches = 1 if num_batches.zero?
        current_start = start
        current_finish = start + batch_size
        (1..num_batches).each do
          # Create Job
          job = product_search_attribute_update_job(current_start, current_finish)

          if async
            ::Products::ProductSearchAttributesRefreshJob.perform_later(job.internal_identifier)
          else
            ::Products::ProductSearchAttributesRefreshJob.new.perform(job.internal_identifier)
          end

          # Now line up remaining
          current_start = current_finish
          current_finish = current_finish + batch_size

          # Limit upper bound
          if current_finish >= finish
            current_finish = finish
          end
        end
        ro.message = 'Successfully queued jobs to refresh cache'
      rescue => ex
        ro.fail_with_exception!(ex)
      end
      ro
    end

    def build_search_attributes_for_products_since!(datetime)
      Spree::Product.with_search_attribute_last_updated_before(datetime).find_each do |p|
        begin
          p.update_search_attributes!
        rescue => ex
          puts "#{ex}"
        end
      end
    end

    def build_search_attributes_for_missing!
      Spree::Product.with_no_search_attribute_timestamp.find_each do |p|
        begin
          p.update_search_attributes!
        rescue => ex
          puts "#{ex}"
        end
      end
    end
  end

  def build_search_attributes
    search_attr = {
      "available_quantity": self.available_quantity,
      "eligible_for_international_sale": self.eligible_for_international_sale,
      "supplier_internal_identifier": self.supplier_internal_identifier,
      "supplier_name": self.supplier_name,
      "supplier_brand_name": self.supplier_brand_name,
      "license_taxons": self.license_taxons,
      "category_taxons": self.category_taxons,
      "custom_collection_taxons": self.custom_collection_taxons,
      "propercase_name": self.propercase_name,
      "product_variants": self.product_variants
    }
    self.search_attributes = search_attr
    self.search_attributes_updated_at = DateTime.now
    search_attr
  end

  def update_search_attributes!
    self.build_search_attributes
    self.save!
  end

  # Use with caution. Better to set the value in the place where
  # build_search_attributes will pull from.
  # This is a convenience method for test purposes primarily.
  def update_search_attribute_value!(key, value)
    # self.search_attributes = build_search_attributes if self.search_attributes == {}
    attr = self.search_attributes.deep_dup
    attr[key] = value
    self.update_columns(
      search_attributes: attr,
      search_attributes_updated_at: DateTime.now
    )
  end
end
