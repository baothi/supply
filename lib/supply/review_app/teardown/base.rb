module Supply
  module ReviewApp
    module Teardown
      class Base
        def run
          Spree::Product.clear_index!
          delete_products_from_shopify
          delete_shopify_webhooks
        end

        def delete_products_from_shopify
          Spree::Retailer.all.each do |retailer|
            retailer.product_listings.each do |listing|
              job = Spree::LongRunningJob.create(
                action_type: 'export',
                job_type: 'approval',
                initiated_by: 'user',
                retailer_id: retailer.id,
                teamable_type: 'Spree::Retailer',
                teamable_id: retailer.id,
                option_1: listing.internal_identifier
              )

              Shopify::ProductShopifyRemovalJob.perform_now(job.internal_identifier)
            end
          end
        end

        def delete_shopify_webhooks
          Spree::Supplier.all.each do |supplier|
            supplier.init
            supplier.webhooks.each(&method(:destroy_webhook))
          end

          Spree::Retailer.all.each do |supplier|
            supplier.init
            supplier.webhooks.each(&method(:destroy_webhook))
          end
        end

        private

        def destroy_webhook(webhook)
          shopify_id = webhook.shopify_identifier
          begin
            shopify_webhook = ShopifyAPIRetry.retry(3) { ShopifyAPI::Webhook.find(shopify_id) }
            result = ShopifyAPIRetry.retry(3) { shopify_webhook.destroy }
            webhook.destroy if result
          rescue
            return
          end
        end
      end
    end
  end
end
