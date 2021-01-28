module Retailer
  class DidNotAddMoreThanTenProductJob < ApplicationJob

    queue_as :mailers

    def perform(job_id)
      begin
        # SupplierMailer.when_the_stock_items_count_on_hand_is_zero(supplier).deliver_later
        job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job! unless job.in_progress?
        RetailerMailer.did_not_add_more_than_ten_product(job.retailer_id).deliver_later
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex)
      end
    end
  end
end
