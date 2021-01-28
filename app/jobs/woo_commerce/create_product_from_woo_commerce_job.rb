module WooCommerce
  class CreateProductFromWooCommerceJob < ApplicationJob
    queue_as :mailers
    def perform(job_id)
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

      @job.initialize_and_begin_job! unless @job.in_progress?

    end
  end
end
