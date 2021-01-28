# The purpose of this class is to quickly be able to run our exporter against
# the desired order, typically after we've fully fi
module Shopify
  module Debug
    class FakeFulfillment
      attr_accessor :errors, :logs

      def initialize(opts)
        @errors = ''
        @logs = ''
        raise 'Order ID needed' if opts[:order_id].blank?

        @order = Spree::Order.find(opts[:order_id])
      end

      def perform
        # Fulfill the order
        @order.line_items.each { |li| li.fulfill_shipment('XXXXXXXXX') }

        # Now export
        shopify = Shopify::Fulfillment::Exporter.new(
          supplier_id: @order.supplier_id,
          retailer_id: @order.retailer_id,
          teamable_type: @order.retailer.class.name,
          teamable_id: @order.retailer.id
        )
        shopify.perform(@order.internal_identifier)
      end
    end
  end
end
