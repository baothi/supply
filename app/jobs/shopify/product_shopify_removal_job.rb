module Shopify
  class ProductShopifyRemovalJob < ApplicationJob
    queue_as :shopify_export

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      shopify_ids = job.option_1.split(',')
      job.update(total_num_of_records: shopify_ids.count)
      retailer = Spree::Retailer.find_by(id: job.retailer_id)

      begin
        shopify = Shopify::Product::ShopifyRemover.new(retailer_id: job.retailer_id)
      rescue => e
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end

      if retailer.init
        shopify_ids.each do |id|
          status = shopify.perform(id)

          job.update_status(status)
        end
      else
        job.log_error('Could not connect to shopify')
        job.raise_issue!
      end

      job.log_error(shopify.errors)
      job.update_log(shopify.logs)
    end
  end
end
