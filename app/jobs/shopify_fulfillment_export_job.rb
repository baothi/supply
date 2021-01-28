class ShopifyFulfillmentExportJob < ApplicationJob
  queue_as :shopify_export

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    order_ids = job.option_1.split(',')
    job.update(total_num_of_records: order_ids.count)

    begin
      fulfillment_service = Shopify::Fulfillment::Exporter.new(
        supplier_id: job.supplier_id,
        retailer_id: job.retailer_id,
        teamable_type: job.teamable_type,
        teamable_id: job.teamable_id
      )
    rescue => e
      puts "#{e}".red
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end

    order_ids.each do |id|
      status = fulfillment_service.perform(id)
      job.update_status(status)
    end

    job.log_error(fulfillment_service.errors)
    job.update_log(fulfillment_service.logs)
  end
end
