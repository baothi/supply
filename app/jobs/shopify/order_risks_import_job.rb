module Shopify
  class OrderRisksImportJob < ApplicationJob
    def perform(job_id)
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      return if @job.nil?

      @job.initialize_and_begin_job! unless @job.in_progress?
      process_job_order
    rescue => e
      @job.log_error(e.to_s)
      @job.raise_issue!
    end

    def process_job_order
      order_ids = @job.option_4.split(',')
      @job.update(total_num_of_records: order_ids.count)

      order_ids.each do |order_id|
        order = Spree::Order.find_by(id: order_id)
        risk = Shopify::Import::OrderRisk.new(order.retailer, order.retailer_shopify_identifier)
        risk.save_order_risks(order) if risk.errors.empty?
        @job.update_status(risk.errors.empty?)
        @job.log_error(risk.errors) if risk.errors.present?
      end
    end
  end
end
