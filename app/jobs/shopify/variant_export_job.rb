module Shopify
  class VariantExportJob < ApplicationJob
    queue_as :shopify_export

    # TODO: Refactor this job to only deal with one order at a time.
    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?
      retailer = Spree::Retailer.find(job.retailer_id)
      listing_id = Spree::ProductListing.find(job.option_1)
      raise 'Retailer Required' if retailer.nil?

      raise 'Could not connect to shopify' unless retailer.initialize_shopify_session!

      begin
        shopify = Shopify::Variant::Exporter.new(listing_id)
      rescue => e
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end

      job.update(total_num_of_records: 1)
      status = shopify.perform
      job.log_error(shopify.errors)
      job.update_log(shopify.logs)
      job.update_status(status)

      retailer.destroy_shopify_session!
    end
  end
end
