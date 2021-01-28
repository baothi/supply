module Retailer
  class RetailerNotSoldAnyProductsIn7DaysJob < ApplicationJob
    queue_as :mailers

    def perform(job_id)
      begin
        job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job! unless job.in_progress?
        RetailerMailer.retailer_not_sold_any_products_in_7days(job.retailer_id).deliver_later
        job.complete_job!
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex)
      end
    end
  end
end
