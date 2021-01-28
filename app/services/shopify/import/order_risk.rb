module Shopify
  module Import
    class OrderRisk
      attr_accessor :shopify_order_risks, :errors

      def initialize(retailer, shopify_order_id)
        @errors = ''
        retailer.init
        @shopify_order_risks = get_order_risks_for(shopify_order_id)
      end

      def save_order_risks(local_order)
        local_order.order_risks.destroy_all
        shopify_order_risks.each do |order_risk|
          Spree::OrderRisk.find_or_create_by(
            shopify_identifier: order_risk.id,
            shopify_order_id: local_order.retailer_shopify_identifier,
            order_id: local_order.id
          ) do |local_order_risk|
            local_order_risk.cause_cancel = order_risk.cause_cancel
            local_order_risk.display = order_risk.display
            local_order_risk.message = order_risk.message
            local_order_risk.recommendation = order_risk.recommendation
            local_order_risk.score = order_risk.score
            local_order_risk.source = order_risk.source
          end
        end

        local_order.update(risk_recommendation: get_highest_risk_recommendation(local_order))
      rescue => e
        @errors << " #{e}\n"
      end

      private

      def get_highest_risk_recommendation(order)
        return 'cancel' if order.order_risks.any? { |r| r.recommendation == 'cancel' }
        return 'investigate' if order.order_risks.any? { |r| r.recommendation == 'investigate' }
        return 'accept' if order.order_risks.any? { |r| r.recommendation == 'accept' }

        ''
      end

      def get_order_risks_for(shopify_order_id)
        ShopifyAPIRetry.retry(3) do
          ShopifyAPI::OrderRisk.find(:all, params: { order_id: shopify_order_id })
        end
      rescue => e
        @errors << " #{e}\n"
        []
      end
    end
  end
end
