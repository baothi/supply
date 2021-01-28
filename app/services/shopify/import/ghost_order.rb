module Shopify
  module Import
    class GhostOrder
      attr_accessor :filtered_line_items
      attr_accessor :line_item_variants
      attr_accessor :retailer
      attr_accessor :created_orders

      def initialize(shopify_order, line_items, line_item_variants, retailer)
        @shopify_order = shopify_order
        @line_item_variants = line_item_variants
        @filtered_line_items = filter_line_items(line_items)
        @retailer = retailer
        @created_orders = []
      end

      def perform
        begin
          # TODO: Disabling ability to use this helper temporarily
          # verify_line_items_belong_to_same_supplier?(line_items)
          # puts 'We are disabling this class for now'.red

          if filtered_line_items.present?
            create_order(filtered_line_items)
          end
        rescue
          false
        end
      end

      def filter_line_items(line_items)
        line_items.select { |l| line_item_variants.key?(l.id.to_s) }
      end

      # Ensure there's an address
      # We have to do this because Shopify doesn't always define these methods
      # and the shipping address isn't always where we think it is.
      def derive_shipping_address
        customer_default_address = @shopify_order.try(:customer).try(:default_address)
        shipping_address = @shopify_order.try(:shipping_address)
        shipping_address || customer_default_address
      end

      def derive_billing_address
        billing_address = @shopify_order.try(:billing_address)
        billing_address || derive_shipping_address
      end

      def validate_order
        shipping_address = derive_shipping_address
        billing_address = derive_billing_address

        puts "Using shipping address #{shipping_address}".yellow
        puts "Using billing address  #{billing_address}".yellow

        raise 'Cannot create draft orders or orders without address.' if
            shipping_address.nil? || billing_address.nil?

        # raise 'Can only support US addresses at this time.' unless
        #     @shopify_order.shipping_address.country_code == 'US'
        raise 'Cannot bring in unpaid orders' unless
          ['paid', 'partially_refunded'].include?(@shopify_order.financial_status)
      end

      def create_order(filtered_line_items)
        begin
          # validate_order

          line_item_grouper_service = Shopify::Import::LineItemGrouper.new(
            retailer: @retailer,
            shopify_line_items: filtered_line_items,
            shopify_order: @shopify_order,
            line_item_variants: line_item_variants,
            # We've already done the difficult job of determining
            # which shipping/billing address to use. This is why
            # we don't simply call shopify_order.shipping_address
            shopify_shipping_address: derive_shipping_address,
            shopify_billing_address: derive_billing_address
          )

          line_item_grouper_service.perform
          sub_orders = line_item_grouper_service.orders

          save_all_orders(sub_orders, @shopify_order)
        rescue => ex
          puts "Ghost Order Creation: Unable to bring in order: #{ex}".black.on_red.blink
          puts "#{ex.backtrace}".black.on_red.blink
          nil
        end
      end

      def verify_line_items_belong_to_same_supplier?(_line_items)
        # TODO: implement
      end

      def save_all_orders(sub_orders, shopify_order)
        return if sub_orders.nil?

        order_risk = Shopify::Import::OrderRisk.new(retailer, shopify_order.id)

        ActiveRecord::Base.transaction do
          # Create all orders - All or None
          # This has bitten us in the past though. The bigger the order, the more likely something
          # is going to be up with one of the sub orders
          sub_orders.each do |local_order|
            save_order(local_order, shopify_order)
            if local_order.reload.persisted?
              order_risk.save_order_risks(local_order) if order_risk.errors.empty?
              created_orders << local_order
            end
          end
        end
      end

      def save_order(local_order, shopify_order)
        raise 'Order cannot be nil' if local_order.nil?

        return unless local_order.line_items.present? && local_order.save!

        local_order.state = 'complete'
        local_order.completed_at = shopify_order.created_at
        local_order.shipment_state = 'pending'
        local_order.save!

        Rails.application.config.spree.stock_splitters =
          [Spree::Stock::Splitter::CustomSplitter]
        local_order.create_proposed_shipments
        local_order.save!
        local_order.post_process_order!
        puts "Order ID: #{local_order.id}".green
      end
    end
  end
end
