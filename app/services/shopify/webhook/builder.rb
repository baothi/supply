module Shopify
  module Webhook
    class Builder < Base
      RETAILER_TOPICS = %w(orders/create products/delete orders/updated app/uninstalled).freeze
      SUPPLIER_TOPICS = %w(products/create products/update products/delete
                           orders/fulfilled orders/partially_fulfilled
                           fulfillments/create fulfillments/update).freeze

      def perform
        current_shopify_store = ShopifyAPI::Shop.current
        puts "Working with #{current_shopify_store.name}".green
        puts "Working with #{current_shopify_store.domain}".green

        old_webhooks = team.webhooks
        old_webhooks.each { |webhook| destroy(webhook) }

        topics.each { |topic| build(topic) }
      end

      def build(topic)
        host = review_app_url || ENV['WEBHOOK_URL']
        address = "#{host}/webhooks/shopify/#{team.friendly_model_name}/#{team.internal_identifier}"
        # puts "Creating: #{address}".yellow

        webhook = {
          address: address,
          topic: topic,
          format: 'json'
        }
        shopify_webhook = ShopifyAPI::Webhook.new(webhook)

        result = ShopifyAPIRetry.retry(3) { shopify_webhook.save }
        save_to_model(shopify_webhook) if result
      end

      def save_to_model(webhook)
        Spree::Webhook.create(
          address: webhook.address,
          topic: webhook.topic,
          teamable: team,
          shopify_identifier: webhook.id
        )
      end

      def topics
        case team.class.to_s
        when 'Spree::Supplier'
          SUPPLIER_TOPICS
        when 'Spree::Retailer'
          RETAILER_TOPICS
        end
      end

      def destroy(webhook)
        shopify_id = webhook.shopify_identifier
        begin
          shopify_webhook = ShopifyAPIRetry.retry(3) { ShopifyAPI::Webhook.find(shopify_id) }
          result = ShopifyAPIRetry.retry(3) { shopify_webhook.destroy }
          webhook.destroy if result
        rescue
          return
        end
      end

      def review_app_url
        return unless Supply::ReviewApp::Helpers.review_app?

        "https://#{Supply::ReviewApp::Helpers.app_name}.herokuapp.com"
      end
    end
  end
end
