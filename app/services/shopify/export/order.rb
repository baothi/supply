module Shopify
  module Export
    class Order
      attr_accessor :errors, :logs

      def initialize
        @errors = ''
        @logs = ''
      end

      def perform(order_id)
        begin
          @order = Spree::Order.find_by(internal_identifier: order_id)
          if @order.supplier_shopify_identifier.present?
            raise "Order #{order.number} already exported"
          end

          @line_items = @order.eligible_line_items

          @order.remit_order!

          if ENV['DISABLE_ORDER_REMITTANCE'] == 'yes'
            ex = "Will not transfer order #: #{@order.number} due to platform maintenance. "\
              'Please try again in 15 minutes.'
            Rollbar.info(ex)
            log_order_issues_to_shopify(ex)
            return false
          end

          @supplier = @order.supplier
          @supplier.initialize_shopify_session!

          shopify_order = ShopifyAPI::Order.new(order_params)
          shopify_order.line_items = []
          shopify_order.shipping_lines = []

          shopify_order = extract_line_items(shopify_order)

          shopify_order.shipping_address = build_shipping_address

          ##
          # Save Shopify Order in a rate-limiting safe way
          ##
          results = ShopifyAPIRetry.retry(5) { shopify_order.save }

          if results.present? && shopify_order.id.present?
            post_export_process(shopify_order)
            return true
          else
            msg = "Could not remit #{@order.internal_identifier} due to missing " \
                'Shopify Object. This typically means it was unable to save.' \
                'Please hit up the tech team - ismail@hingeto.com'
            notify_admins_of_issue_with_remittance(msg)
            log_order_issues_to_shopify(msg)
            @supplier.destroy_shopify_session!
            return false
          end
        rescue => ex
          @errors << "#{ex} \n"
          notify_admins_of_issue_with_remittance(ex)
          log_order_issues_to_shopify(ex)
          return false
        end
      end

      def extract_line_items(shopify_order)
        raise 'Line Items missing' if @line_items.nil?

        @line_items.each do |line_item|
          shopify_variant = get_shopify_variant(line_item)
          puts "shopify_variant #{shopify_variant}".yellow
          next unless shopify_variant.present?

          shopify_line_item = ShopifyAPI::LineItem.new(
            line_item_params(line_item, shopify_variant)
          )
          shipping_line_item = ShopifyAPI::ShippingLine.new(
            shipping_line_item_params(line_item, shopify_variant)
          )
          shopify_order.line_items << shopify_line_item
          shopify_order.shipping_lines << shipping_line_item
        end
        shopify_order
      end

      def log_order_issues_to_shopify(ex)
        begin
          @order.update_shopify_logs(ex) unless
            @order.nil?
        rescue => ex
          puts "#{ex}".red
          false
        end
      end

      def notify_admins_of_issue_with_remittance(ex)
        OrdersMailer.remittance_issue(@order, ex).deliver_now
      end

      def order_params
        retailer = @order.retailer
        # The retailer object has the same properties in DB as address on it - except 'state'
        # but we have a method to overcome this
        address = if retailer.shipping_address.present?
                    retailer.shipping_address
                  else
                    retailer.default_address_model
                  end

        order_hash = {
          email: @order.retailer_email,
          customer: {
            "first_name": "#{address.business_name || retailer.name}",
            "last_name": "#{retailer.shop_owner}",
            "email": @order.retailer_email
          },
          inventory_behaviour: 'decrement_obeying_policy',
          total_price: @order.grand_total,
          subtotal_price: @order.amount,
          tags: 'hingeto',
          financial_status: 'paid',
          note_attributes:  {
            "Retailer Name":  address.business_name || retailer.name,
            "Retailer Store Owner":  address.business_name || retailer.name,
            "Retailer Operator":  retailer.shop_owner,
            "Retailer Address 1":  address.address1,
            "Retailer Address 2":  address.address2,
            "Retailer City":  address.city,
            "Retailer State":  address.name_of_state,
            "Retailer Zip Code":  address.zipcode,
            "Retailer Country":  address.country_iso,
            "Retailer Phone":  address.phone
          }
        }

        order_hash.deep_merge!(used_credit_params) if @order.supplier_discount.positive?
        order_hash
      end

      def used_credit_params
        {
          tags: 'hingeto,credit-applied',
          note_attributes: {
            "Retailer Credit Discount": @order.supplier_discount
          }
        }
      end

      def line_item_params(line_item, shopify_variant)
        # variant = line_item.variant
        {
            variant_id: shopify_variant.id,
            title: line_item.variant.product.name,
            quantity: line_item.quantity,
            order_number: @order.number,
            product_id: shopify_variant.product_id,
            name: shopify_variant.title,
            price: line_item.cost_from_master
        }
      end

      def shipping_line_item_params(line_item, shopify_variant)
        {
            code: 'Shipping',
            price: line_item.line_item_shipping_cost,
            source: 'Hingeto',
            title: 'Shipping',
            variant_id: shopify_variant.id
        }
      end

      def get_shopify_variant(line_item)
        variant = line_item.variant
        begin
          val = ShopifyAPIRetry.retry(5) { ShopifyAPI::Variant.find(variant.shopify_identifier) }
          val
        rescue
          @errors << "Could not find corresponding MXED variant \n"
          nil
        end
      end

      def build_shipping_address
        shipping_address = @order.shipping_address
        {
            address1: shipping_address.address1,
            address2: shipping_address.address2,
            first_name: shipping_address.firstname,
            last_name: shipping_address.lastname,
            country: shipping_address.country&.name,
            phone: shipping_address.phone,
            company: shipping_address.company,
            zip: shipping_address.zipcode,
            # province: shipping_address.state&.name,
            province: shipping_address.name_of_state,
            city: shipping_address.city,
            country_code: shipping_address.country&.iso,
            default: true
        }
      end

      def create_fulfillment_for_non_manual_fulfillment_service(shopify_order)
        line_items = shopify_order.line_items
        services = Hash.new
        line_items.each do |item|
          next if item.fulfillment_service == 'manual'

          services[item.fulfillment_service] ||= []
          services[item.fulfillment_service] << item
        end

        services.each_value do |items|
          fulfillment = ShopifyAPIRetry.retry(5) do
            ShopifyAPI::Fulfillment.new(
              order_id: shopify_order.id,
              location_id: @retailer.default_location_shopify_identifier
            )
          end
          fulfillment.line_items = items
          ShopifyAPIRetry.retry(5) { fulfillment.save }
        end
      end

      def post_export_process(shopify_order)
        @order.update(
          supplier_shopify_identifier: shopify_order.id,
          supplier_shopify_order_number: shopify_order.order_number,
          supplier_shopify_number: shopify_order.number,
          supplier_shopify_order_name: shopify_order.name,
          shopify_sent_at: shopify_order.created_at
        )
        @order.set_compliance_dates(shopify_order.created_at.to_datetime)
        create_fulfillment_for_non_manual_fulfillment_service(shopify_order)
        @order.complete_remittance!
        log_order_issues_to_shopify('Remittance Completed')
        @supplier.destroy_shopify_session!
      end
    end
  end
end
