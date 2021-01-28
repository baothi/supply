# The purpose of this class is to help us create fake Retailer
# products - typically to test that the export process is working well.
module Shopify
  module Debug
    class FakeProduct
      attr_accessor :errors, :logs, :retailer, :supplier,
                    :num_of_line_items, :other_variants

      def initialize(opts)
        @errors = ''
        @logs = ''
        @shopify_order = nil

        raise 'Retailer needed' if opts[:retailer_id].blank?
        raise 'Supplier needed' if opts[:supplier_id].blank?
        raise 'Number of Line Items Needed' if
            opts[:num_of_line_items].blank?

        @retailer = Spree::Retailer.find(opts[:retailer_id])
        @retailer.init

        @supplier = Spree::Supplier.find(opts[:supplier_id])
        @num_of_line_items = opts[:num_of_line_items]
        raise 'Invalid Count' unless @num_of_line_items.positive?

        @other_variants = []
        @other_variants = opts[:other_variants]
      end

      def select_random_variants
        selected_variant_listings = []
        variant_listings = retailer.variant_listings
        while selected_variant_listings.count < @num_of_line_items.to_i
          random_variant_listing = variant_listings.sample
          selected_variant_listings << random_variant_listing unless
              selected_variant_listings.include?(random_variant_listing)
        end
        puts "Added #{selected_variant_listings.count} elements to work with".yellow
        selected_variant_listings
      end

      def create_shopify_line_item(local_variant)
        shopify_line_item = ShopifyAPI::LineItem.new(
          line_item_params(local_variant)
        )
        shopify_line_item
      end

      def assign_local_variants
        # Find Live Products/Variants to use
        variant_listings = select_random_variants

        variant_listings.each do |variant_listing|
          shopify_variant = get_shopify_variant(variant_listing)
          next unless shopify_variant.present?

          shopify_line_item = ShopifyAPI::LineItem.new(
            line_item_params(shopify_variant)
          )
          shipping_line_item = ShopifyAPI::ShippingLine.new(
            shipping_line_item_params(shopify_variant)
          )
          @shopify_order.line_items << shopify_line_item
          @shopify_order.shipping_lines << shipping_line_item
        end
      end

      # Add Additional Products (non-Hingeto). Useful for testing
      # fringe situations where we want to test mixed orders (orders with MXED products)
      # and with the retailers other products
      def assign_other_variants
        results = build_line_items_for_other_variants
        other_line_items = results[0]
        other_shipping_lines = results[1]

        puts "#{other_line_items}".yellow
        other_line_items.each do |other_line_item|
          @shopify_order.line_items << other_line_item
        end

        other_shipping_lines.each do |shipping_line_item|
          @shopify_order.shipping_lines << shipping_line_item
        end
      end

      # Once fake order is created at Shopify, we can manually pull it in using importer
      # if doesn't already do so (due to webhook)

      def perform
        begin
          # First Create the Shopify Order
          @shopify_order = ShopifyAPI::Order.new(order_params)
          @shopify_order.line_items = []
          @shopify_order.shipping_lines = []

          # Hingeto Products
          assign_local_variants

          # Other Non-Hingeto
          assign_other_variants

          # Add Shipping
          @shopify_order.shipping_address = build_shipping_address

          # Save Order
          if @shopify_order.save
            puts 'Successfully created Shopify Order'.green
          else
            puts 'There was an issue creating this order.'.red
            puts "#{@shopify_order.inspect}".yellow
          end
        rescue => ex
          puts "#{ex}".red
          puts "#{ex.backtrace}".red
        end
      end

      def build_line_items_for_other_variants
        shopify_line_items = []
        shopify_shipping_items = []
        return [[], []] if @other_variants.nil?

        @other_variants.each do |shopify_variant_id|
          shopify_variant = ShopifyAPI::Variant.find(shopify_variant_id)

          # Regular Line Item
          shopify_line_item = ShopifyAPI::LineItem.new(
            line_item_params(shopify_variant)
          )
          shopify_line_items << shopify_line_item

          # Shipping Line
          shipping_line_item = ShopifyAPI::ShippingLine.new(
            shipping_line_item_params(shopify_variant)
          )

          shopify_shipping_items << shipping_line_item
        end
        [shopify_line_items, shopify_shipping_items]
      end

      def line_item_params(shopify_variant)
        {
            variant_id: shopify_variant.id,
            quantity: 1,
            product_id: shopify_variant.product_id,
            name: shopify_variant.title
        }
      end

      def get_shopify_variant(variant_listing)
        begin
          ShopifyAPI::Variant.find(variant_listing.shopify_identifier)
        rescue => ex
          puts "Variant Not Found: #{ex}".red
          nil
        end
      end

      def order_params
        {
            email: "#{Faker::Name.first_name.downcase}@hingeto.com",
            customer: {
                "first_name": Faker::Name.first_name,
                "last_name": Faker::Name.last_name,
                "email": "#{Faker::Name.first_name.downcase}@hingeto.com"
            },
            total_price: 500,
            subtotal_price: 400,
            financial_status: 'paid',
            inventory_behaviour: 'decrement_obeying_policy',
            tags: 'hingeto, fake_order',
            note: 'This is a fake order from Hingeto.'
        }
      end

      def shipping_line_item_params(shopify_variant)
        {
            code: 'Shipping',
            price: 0,
            source: 'Hingeto',
            title: 'Shipping',
            variant_id: shopify_variant.id
        }
      end

      def build_shipping_address
        {
            address1: Faker::Address.street_name,
            address2: Faker::Address.secondary_address,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            country: 'USA',
            phone: '555555555',
            company: 'Fake Company',
            zip: Faker::Address.zip_code,
            province: Faker::Address.state,
            city: Faker::Address.city,
            country_code: 'US',
            default: true
        }
      end
    end
  end
end
