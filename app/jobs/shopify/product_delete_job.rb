module Shopify
  class ProductDeleteJob < ApplicationJob
    queue_as :shopify_import

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        shopify = Shopify::Product::Deleter.new(
          supplier_id: job.supplier_id,
          retailer_id: job.retailer_id,
          teamable_type: job.teamable_type,
          teamable_id: job.teamable_id
        )
      rescue => e
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end

      product_ids = job.option_4.split(',')
      job.update(total_num_of_records: product_ids.count)
      if shopify.connected
        product_ids.each do |id|
          status = shopify.perform(id)
          job.update_status(status)
        end
      else
        job.log_error(shopify.connection_error)
        job.raise_issue!
      end

      job.log_error(shopify.errors)
      job.update_log(shopify.logs)
      job.complete_job! if job.may_complete_job?
    end
  end
end
