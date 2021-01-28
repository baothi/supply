# The purpose of this class is to help us create fake Retailer Order Risks at Shopify to import
module Shopify
  module Debug
    class FakeOrderRisk
      attr_accessor :retailer, :supplier,
                    :num_of_line_items, :other_variants

      def initialize(opts)
        @shopify_order = nil

        raise 'Order Identifier needed' if opts[:order_identifier].blank?

        @order = Spree::Order.find_by(internal_identifier: opts[:order_identifier])
        raise 'Invalid order' if @order.blank?

        @retailer = @order.retailer
        @retailer.init
      end

      def perform
        begin
          risk = create_fake_risk(@order.retailer_shopify_identifier)
          puts "Order Risk Created #{risk.id}".green
        rescue => ex
          puts "#{ex}".red
        end
      end

      def create_fake_risk(shopify_order_id)
        v = ShopifyAPI::OrderRisk.new(order_id: shopify_order_id)
        v.message = 'This order was placed from a proxy IP'
        v.recommendation = 'cancel'
        v.score = '1.0'
        v.source = 'External'
        v.merchant_message = 'This order was placed from a proxy IP'
        v.display = true
        v.cause_cancel = true
        v.save
        v
      end

      def delete_all_risks
        order_id = @order.retailer_shopify_identifier
        v = ShopifyAPI::OrderRisk.find(:all, params: { order_id: order_id })
        v.map(&:destroy)
      end
    end
  end
end
