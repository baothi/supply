module Retailer
  class FirstProductEmailJob < ApplicationJob

    queue_as :mailers

    def perform(job_id)
      begin
        job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job! unless job.in_progress?

        RetailerMailer.send_email_when_retailer_created_first_product(job.retailer_id, job.supplier_id, (job.option_1).to_i).deliver_later
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex)
      end
    end
  end
end

