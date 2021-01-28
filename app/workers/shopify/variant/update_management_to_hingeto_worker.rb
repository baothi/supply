class Shopify::Variant::UpdateManagementToHingetoWorker
  include Sidekiq::Worker

  include CancellableJob

  # sidekiq_options queue: 'inventory_worker',
  #                 backtrace: true,
  #                 retry: 3

  sidekiq_options queue: 'inventory_syndication',
                  backtrace: true,
                  retry: 3

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?
    @retailer = Spree::Retailer.find_by(id: job.retailer_id)
    listings_shopify_ids = @retailer.product_listings.pluck(:shopify_identifier)

    @retailer.create_fulfillment_service
    # This also initializes the shopify

    listings_shopify_ids.each_slice(250) do |ids|
      shopify_products = ShopifyAPIRetry.retry do
        ShopifyAPI::Product.find(:all, params: { ids: ids.join(','), limit: 250 })
      end
      begin
        shopify_variants = shopify_products.map(&:variants).flatten
        shopify_variants.each do |sv|
          next if sv.fulfillment_service == ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME']
          next if sv.inventory_management == ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME']

          sv.fulfillment_service = ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME']
          sv.inventory_management = ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME']

          ShopifyAPIRetry.retry { sv.save }

          puts "#{sv.inspect}".blue
          mark_as_transitioned_locally!(sv)
        end
      rescue => e
        puts "#{e}".red
        Rollbar.error(e, job_id: job_id, error: 'Error while updating inventory management')
      end
    end
  end

  def mark_as_transitioned_locally!(shopify_variant)
    Spree::VariantListing.where(
      shopify_identifier: shopify_variant.id
    ).update_all(shopify_management_switched_to_hingeto_at: DateTime.now)
  end
end
