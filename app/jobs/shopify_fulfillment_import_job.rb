class ShopifyFulfillmentImportJob < ApplicationJob
  queue_as :shopify_import

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    order_ids = job.option_1.split(',')
    job.update(total_num_of_records: order_ids.count)

    begin
      shopify = Shopify::Fulfillment::Importer.new(
        supplier_id: job.supplier_id,
        teamable_type: job.teamable_type,
        teamable_id: job.teamable_id
      )
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end

    if shopify.connected
      order_ids.each do |id|
        status = shopify.perform(id)
        export_fulfillment(id, job) if status
        job.update_status(status)
      end
    else
      job.log_error(shopify.connection_error)
      job.raise_issue!
    end

    job.log_error(shopify.errors)
    job.update_log(shopify.logs)
  end

  private

  def export_fulfillment(id, job)
    begin
      order = Spree::Order.find_by(internal_identifier: id)
      return if order.source == 'app'

      export_job = Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'orders_export',
        initiated_by: 'system',
        option_1: order.internal_identifier,
        retailer_id: order.retailer_id
      )
      ShopifyFulfillmentExportJob.perform_later(export_job.internal_identifier)
    rescue
      job.log_error("Could not auto export imported fulfillment \n")
    end
  end
end
