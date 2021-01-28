module Shopify
  module Import
    class OrderValidator
      attr_accessor :shopify_shipping_address, :shopify_billing_address, :errors, :logs

      def initialize(opts)
        @shopify_order = opts[:shopify_order]
        raise 'Shopify Order is required' if
            @shopify_order.nil?

        @shopify_shipping_address = nil
        @shopify_billing_address = nil

        @errors = ''
        @logs = ''
      end

      def perform
        begin
          validate_address
          validate_financial_status
          puts 'Successfully validated order'.green
          true
        rescue => ex
          @errors << "#{ex}\n"
          puts "OrderValidator: #{ex}".red
          false
        end
      end

      # Ensure there's an address
      # We have to do this because Shopify doesn't always define these methods
      # and the shipping address isn't always where we think it is.
      def derive_shopify_shipping_address
        customer_default_address = @shopify_order.try(:customer).try(:default_address)
        shopify_shipping_address = @shopify_order.try(:shipping_address)
        @shopify_shipping_address = shopify_shipping_address || customer_default_address
        @shopify_shipping_address
      end

      def derive_shopify_billing_address
        shopify_billing_address = @shopify_order.try(:billing_address)
        @shopify_billing_address = shopify_billing_address || derive_shopify_shipping_address
        @shopify_billing_address
      end

      def validate_financial_status
        raise 'Cannot bring in unpaid orders' unless
            @shopify_order.financial_status == 'paid' ||
            @shopify_order.financial_status == 'partially_refunded'
      end

      def validate_address
        derive_shopify_shipping_address
        derive_shopify_billing_address

        puts "Using shipping address #{@shopify_shipping_address}".yellow
        puts "Using billing address  #{@shopify_billing_address}".yellow

        raise 'Cannot create draft orders or orders without address.' if
            @shopify_shipping_address.nil? || @shopify_billing_address.nil?
      end

      def validate_us_only
        # raise 'Can only support US addresses at this time.' unless
        #     @order.shopify_shipping_address.country_code == 'US'
      end
    end
  end
end
