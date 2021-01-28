class ShopifyOrderExportJob < ApplicationJob
  queue_as :shopify_export

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    order_ids = job.option_1.split(',')
    job.update(total_num_of_records: order_ids.count)

    begin
      # Every order has supplier on the model, so we will not pass the supplier.
      shopify = Shopify::Export::Order.new(
        supplier_id: nil,
        retailer_id: job.retailer_id,
        teamable_type: nil,
        teamable_id: nil
      )
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end

    if shopify.connected
      order_ids.each do |id|
        status = shopify.perform(id)
        job.update_status(status)
      end
    else
      job.log_error(shopify.connection_error)
      job.raise_issue!
    end

    job.log_error(shopify.errors)
    job.update_log(shopify.logs)
  end
end
