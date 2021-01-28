module Shopify
  class FulfillmentServiceCreationJob < ApplicationJob
    queue_as :shopify_export

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      if job.teamable_type != 'Spree::Retailer'
        job.log_error('Cannot run for Suppliers.')
        return
      end

      begin
        retailer = Spree::Retailer.find(job.retailer_id)

        if retailer.default_location_shopify_identifier.present?
          job.log_error('This retailer already has a fulfillment service')
        else
          retailer.create_fulfillment_service
        end

        job.update(total_num_of_records: 1)
        job.update_status(true)
      rescue => e
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end
    end
  end
end
