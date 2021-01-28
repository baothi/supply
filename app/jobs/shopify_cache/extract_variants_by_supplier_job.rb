module ShopifyCache
  class ExtractVariantsBySupplierJob < ApplicationJob
    queue_as :exports

    def perform(job_id)
      begin
          @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

          @job.initialize_and_begin_job! unless @job.in_progress?

          supplier_id = @job.supplier_id
          raise 'Supplier ID is required' if supplier_id.nil?

          supplier = Spree::Supplier.find(supplier_id)
          supplier_query = {
              shopify_url: supplier.shopify_url,
              role: 'supplier'
          }

          ShopifyCache::Product.
              has_not_yet_generated_variants.where(supplier_query).all.each do |cached_product|
            begin
              cached_product.extract_variants!
            rescue => ex
              puts "#{ex}".red
            end
          end
        end

      @job.complete_job!
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end
  end
