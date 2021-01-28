module Shopify
  class WebhookCreationJob < ApplicationJob
    queue_as :shopify_export

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        shopify = Shopify::Webhook::Builder.new(
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

      if shopify.connected
        job.update(total_num_of_records: 1)
        shopify.perform
        job.update_status(true)
      else
        job.log_error(shopify.connection_error)
        job.raise_issue!
      end

      job.log_error(shopify.errors)
      job.update_log(shopify.logs)
    end
  end
end
