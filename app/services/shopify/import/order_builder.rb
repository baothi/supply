module Shopify
  module Import
    class OrderBuilder
      attr_accessor :retailer, :supplier, :order, :errors, :logs
      def initialize(opts)
        @errors = ''
        @logs = ''
        @shopify_order = opts[:shopify_order]
        raise 'Shopify Order is required' if @shopify_order.nil?

        # Important: We assume all of these line items belong to the same local order
        # and to the same supplier
        # i.e. see Shopify::Import::LineItemGrouper
        @line_items = opts[:line_items]
        @shopify_shipping_address = opts[:shopify_shipping_address]
        @shopify_billing_address = opts[:shopify_billing_address]

        # We can infer the supplier from the variants in the order
        # since we only support one order per supplier

        @supplier = @line_items.first.supplier
        raise 'Supplier is required' if @supplier.nil?

        @retailer = opts[:retailer]
        raise 'Retailer is required' if @retailer.nil?

        @order = nil
      end

      def perform
        begin
          build_order
          true
        rescue => e
          @errors << " #{e}\n"
          false
        end
      end

      def build_order
        begin
          @order = Spree::Order.new(order_params)
          @order.total = total_price(@line_items)
          @order.line_items << @line_items

          puts "#{@order}".yellow

          @order
        rescue => e
          @errors << " #{e}\n"
          nil
        end
      end

      def order_params
        {
          retailer_shopify_number: @shopify_order.number,
          retailer_shopify_order_number: @shopify_order.order_number,
          retailer_shopify_name: @shopify_order.name,
          email: 'customer@hingeto.com',
          customer_email: @shopify_order.contact_email,
          shipping_address: shipping_address,
          billing_address: billing_address,
          retailer_id: @retailer.id,
          supplier_id: @supplier.id,
          retailer_shopify_identifier: @shopify_order.id
        }
      end

      def total_price(line_items)
        total = 0
        line_items.each do |l|
          total = total + (l.price.to_f * l.quantity.to_f)
        end
        total
      end

      def non_blank_value(val)
        to_return = val.blank? ? 'N/A' : val
        to_return
      end

      def billing_address
        begin
          address = Spree::Address.new(address_params(@shopify_billing_address))
          address.save!
          address
        rescue
          @errors << "Invalid Billing Address \n"
          nil
        end
      end

      def shipping_address
        begin
          address = Spree::Address.new(address_params(@shopify_shipping_address))
          address.save!
          address
        rescue
          @errors << "Invalid Shipping Address \n"
          nil
        end
      end

      def address_params(address)
        country = Spree::Country.find_by(iso: address.country_code) ||
                  Spree::Country.find_by(iso3: address.country_code)
        state = Spree::State.find_or_create_by(
          name: 'NOT_IN_USE',
          abbr: 'NOT_IN_USE',
          country: country
        )
        {
            firstname: non_blank_value(address.first_name),
            lastname: non_blank_value(address.last_name),
            address1: address.address1,
            address2: address.address2,
            city: non_blank_value(address.city),
            zipcode: non_blank_value(address.zip),
            phone: non_blank_value(address.phone),
            name_of_state: address.province_code,
            state_id: state.id,
            country_id: country.id
        }
      end
    end
  end
end
