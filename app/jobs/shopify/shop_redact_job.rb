module Shopify
  class ShopRedactJob < ApplicationJob
    queue_as :shopify_import

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        shopify = Shopify::Order::Deleter.new(
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

      retailer = Spree::Retailer.find_by(domain: job.option_3)
      retailer_order = Spree::Order.where(retailer_id: retailer.id)
      job.update(total_num_of_records: retailer_order.count)
      if shopify.connected
        retailer_order.each do |order|
          status = shopify.perform(order.retailer_shopify_identifier)
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
