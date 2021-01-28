module Shopify
  class UnpublishJob < ApplicationJob
    queue_as :shopify_export

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        product_id = job.option_1

        product = Spree::Product.find(product_id)
        product_listings = product.product_listings
        job.update(total_num_of_records: product_listings.count)

        product_listings.each do |product_listing|
          begin
            updater = Shopify::Product::LiveUnpublisher.new(
              product_listing: product_listing,
              product: product
            )
            updater.perform
            job.update_status(true)
          rescue => ex
            puts "Issue Updating for #{product_listing.internal_identifier} "\
              "for #{product_listing.retailer.name}"
            puts "#{ex}".red
            job.update_status(false)
            job.log_error(ex.to_s)
          end
        end
      rescue => e
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end
    end
  end
end
