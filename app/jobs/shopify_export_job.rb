class ShopifyExportJob < ApplicationJob
  queue_as :shopify_export

  def perform(job_id)
    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    @product_ids = @job.option_1.split(',')
    @job.update(total_num_of_records: @product_ids.count)
    retailer = Spree::Retailer.find_by(id: @job.retailer_id)
    raise 'No Retailer found' unless retailer.present?

    raise 'Could not connect to Shopify' unless retailer.initialize_shopify_session!

    begin
      @shopify_service = Shopify::Product::Exporter.new(
        retailer_id: @job.retailer_id
      )
    rescue => e
      @job.log_error(e.to_s)
      @job.raise_issue!
      return
    end

    export_products

    @job.log_error(@shopify_service.errors)
    @job.update_log(@shopify_service.logs)
    retailer.destroy_shopify_session!
  end

  private

  def export_products
    sleep_time =
      ENV['PRODUCT_EXPORT_SLEEP_TIME'].present? ? ENV['PRODUCT_EXPORT_SLEEP_TIME'].to_i : 2
    @product_ids.each do |id|
      status = @shopify_service.perform(id)
      @job.update_status(status)
      sleep(sleep_time)
    end
  end
end
