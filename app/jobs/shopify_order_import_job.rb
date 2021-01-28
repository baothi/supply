class ShopifyOrderImportJob < ApplicationJob
  queue_as :shopify_import

  def perform(job_id)
    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    begin
      shopify = Shopify::Import::Order.new(@job.id)
    rescue => e
      @job.log_error(e.to_s)
      @job.raise_issue!
      return
    end

    begin
      retailer.initialize_shopify_session!
      @job.update(total_num_of_records: get_total(shopify))

      if @job.option_1 == 'mass'
        shopify_orders = get_mass_orders(shopify)
      elsif @job.option_1 == 'webhook'
        shopify_orders = get_webhook_orders
      end
      process_orders(shopify_orders, shopify)

      if @job.option_1 == 'mass'
        while shopify_orders.next_page?
          shopify_orders = shopify_orders.fetch_next_page
          process_orders(shopify_orders, shopify)
        end
      end

      retailer.destroy_shopify_session!
    rescue => e
      @job.log_error(e.to_s)
      @job.raise_issue!
    end

    log_shopify_service_performance(shopify)
  end

  def process_orders(shopify_orders, shopify)
    shopify_orders.each do |order|
      # The Shopify service (shopify.perform) is somehow unsetting the Shopify session
      # so we forcefully reinitialize the session again
      retailer.initialize_shopify_session!
      status = shopify.perform(order)
      @job.update_status(status)
    end
  end

  def log_shopify_service_performance(shopify)
    return if @job.nil?

    @job.log_error(shopify.errors)
    @job.update_log(shopify.logs)
    @job.complete_job! if @job.may_complete_job?
  end

  def get_mass_orders(shopify)
    shopify.find_in_batches('ShopifyAPI::Order', @job.option_2, @job.option_3)
  end

  def get_webhook_orders
    ids = @job.option_4.split(',')
    ids.map { |id| ShopifyAPI::Order.find(id) }
  end

  def get_total(shopify)
    if @job.option_1 == 'mass'
      shopify.get_total_records('ShopifyAPI::Order', @job.option_2, @job.option_3)
    elsif @job.option_1 == 'webhook'
      1
    end
  end

  def retailer
    Spree::Retailer.find_by(id: @job.retailer_id)
  end
end
