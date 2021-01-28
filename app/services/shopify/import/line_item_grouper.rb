# The purpose of this service is to help group line_items by their supplier
# so that we can create separate orders by suppliers in Shopify::Import::Order

module Shopify
  module Import
    class LineItemGrouper
      attr_reader :line_items, :orders, :logs, :errors

      def initialize(opts = {})
        @logs = ''
        @errors = ''
        # Current Retailer
        @retailer = opts[:retailer]
        raise 'Retailer is required' if @retailer.nil?

        @shopify_order = opts[:shopify_order]
        raise 'Shopify Order cannot be nil' if
            @shopify_order.nil?

        # Original shopify line items from retailer.
        @shopify_line_items = opts[:shopify_line_items]
        raise 'Shopify Line Items cannot be empty' if
            @shopify_line_items.nil? || @shopify_line_items.empty?

        # Addresses to pass to Order Builder.
        @shopify_billing_address = opts[:shopify_billing_address]
        @shopify_shipping_address = opts[:shopify_shipping_address]

        # Line items post-translation to our system
        @line_items = []

        # Line Items Grouped by their Supplier
        @split_line_items = {}

        # List of orders to return for creation
        @orders = []

        # We use this to handle ghost/manual order import
        @line_item_variants = opts[:line_item_variants]
      end

      def perform
        build_line_items
        split_line_items_by_supplier
        group_orders_by_line_item
      end

      def build_line_items
        @shopify_line_items.each do |shopify_line_item|
          @line_items << build_local_line_item(shopify_line_item)
        end
        @line_items
      end

      def split_line_items_by_supplier
        # First find all the line items

        @line_items.each do |line_item|
          supplier_id =  line_item.supplier_id.to_s
          raise 'Invalid Supplier ID' if supplier_id.blank?

          # We use symbols for the key; :supplier_id
          key = supplier_id.to_sym

          # Create array for supplier if doesn't exist
          @split_line_items[key] = [] unless
              @split_line_items.key?(key)

          # Add to array of line items for this supplier
          @split_line_items[key] << line_item
        end
      end

      def group_orders_by_line_item
        # Now that order has been grouped by supplier, create / build orders for each
        @split_line_items.each_key do |key|
          opts = {}
          line_items = @split_line_items[key]

          opts[:line_items] = line_items
          opts[:shopify_shipping_address] = @shopify_shipping_address
          opts[:shopify_billing_address] = @shopify_billing_address
          opts[:shopify_order] = @shopify_order
          opts[:retailer] = @retailer

          # Build Orders
          order = build_order(opts)
          @orders << order
        end

        puts 'Regular Line Items:'
        puts "#{line_items}".yellow

        puts 'Split Line Items:'
        puts "#{@split_line_items}".yellow

        puts 'Results of order hash:'.yellow
        puts "#{@orders}".green
      end

      def build_order(opts)
        order_builder_service = Shopify::Import::OrderBuilder.new(opts)
        order_builder_service.perform

        order = order_builder_service.order

        @errors << order_builder_service.errors
        @logs << order_builder_service.logs

        puts 'Built Order'
        puts "#{order}".blue
        order
      end

      def build_local_line_item(shopify_line_item)
        local_variant = get_variant(shopify_line_item)

        # By the time this is called, we've already validated that
        # all line_items are good to go. If this gets raised,
        # something serious has happened.
        # raise 'Invalid Variant Found. Likely not a MXED product' if
        #    local_variant.nil?

        Spree::LineItem.new(
          line_item_param(shopify_line_item, local_variant)
        )
      end

      def line_item_param(shopify_line_item, local_variant)
        {
            variant: local_variant,
            quantity: shopify_line_item.quantity,
            price: local_variant.price_based_on_retailer(@retailer),
            sold_at_price: shopify_line_item.price,
            retailer_shopify_identifier: shopify_line_item.id,
            retailer_id: @retailer.id,
            supplier_id: local_variant.supplier_id
        }
      end

      def get_variant(shopify_line_item)
        if  @line_item_variants.present?
          return nil if Spree::LineItem.find_by(
            retailer_shopify_identifier: shopify_line_item.id
          ).present?

          variant_internal_identifier = @line_item_variants[shopify_line_item.id.to_s]
          Spree::Variant.find_by(internal_identifier: variant_internal_identifier)
        else
          VariantLineItemMatcher.new(
            shopify_line_item, @retailer
          ).perform
        end
      end
    end
  end
end
