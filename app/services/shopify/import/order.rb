module Shopify
  module Import
    class Order < Base
      attr_accessor :job, :retailer, :errors, :logs
      def initialize(job_id)
        @job = Spree::LongRunningJob.find_by(id: job_id)
        @retailer = Spree::Retailer.find(@job.retailer_id)
        @errors = ''
        @logs = ''
      end

      def perform(shopify_order)
        validation_service = validate_order(shopify_order)
        return unless validation_service

        shopify_shipping_address = validation_service.shopify_shipping_address
        shopify_billing_address = validation_service.shopify_billing_address

        begin
          # Filter all the relevant Shopify Line Items
          filtered_shopify_line_items = Shopify::Import::FilterLineItem.new(
            order: shopify_order,
            retailer: @retailer
          ).perform

          if filtered_shopify_line_items.present?
            num_lines = filtered_shopify_line_items.count
            puts "#{filtered_shopify_line_items}".yellow
            @logs << "Proceeding with creating order with #{num_lines} items.\n"
          else
            @logs << "Skipping order as no valid MXED line items present.\n"
            return
          end

          # Locally built sub-orders.
          # We create an order per supplier on the original retailer order
          line_item_grouper_service = Shopify::Import::LineItemGrouper.new(
            retailer: @retailer,
            shopify_line_items: filtered_shopify_line_items,
            shopify_order: shopify_order,
            # We've already done the difficult job of determining
            # which shipping/billing address to use. This is why
            # we don't simply call shopify_order.shipping_address
            shopify_shipping_address: shopify_shipping_address,
            shopify_billing_address: shopify_billing_address
          )

          line_item_grouper_service.perform
          @errors << line_item_grouper_service.errors
          @logs << line_item_grouper_service.logs

          sub_orders = line_item_grouper_service.orders

          # Save all or none!
          # log_to_console(sub_orders)
          save_all_orders(sub_orders, shopify_order)

          true
        rescue => e
          puts "#{@errors}".red
          puts "#{@logs}".yellow
          @errors << " #{e}\n"
          false
        end
      end

      def log_to_console(sub_orders)
        puts 'Did not create any sub_orders!'.red if
            sub_orders.nil? || sub_orders.empty?

        puts "Found #{sub_orders.count} sub orders!".yellow unless
            sub_orders.nil?

        puts sub_orders.inspect unless
            sub_orders.nil? || sub_orders.empty?
      end

      def save_all_orders(sub_orders, shopify_order)
        return if sub_orders.nil?

        # Create all orders - All or None
        # This has bitten us in the past though. The bigger the order, the more likely something
        # is going to be up with one of the sub orders

        ActiveRecord::Base.transaction do
          # Create all orders
          sub_orders.each do |local_order|
            local_order = save_order(local_order, shopify_order)
            local_order.generate_internal_storefront_line_item_identifiers!
          end
        end

        # Now import risks
        order_risk = Shopify::Import::OrderRisk.new(retailer, shopify_order.id)
        sub_orders.each do |local_order|
          order_risk.save_order_risks(local_order) if order_risk.errors.empty?
        end

        @errors << order_risk.errors
      end

      def save_order(local_order, shopify_order)
        raise 'Order cannot be nil' if local_order.nil?

        return unless local_order.line_items.present? && local_order.save!

        local_order.state = 'complete'
        local_order.completed_at = shopify_order.created_at
        local_order.shipment_state = 'pending'
        local_order.save!
        # Post Process Order
        local_order.post_process_order!
        if job.setting_attempt_auto_pay
          local_order.attempt_start_auto_payment!
        end
        puts "Order ID: #{local_order.id}".green
        local_order
      end

      def validate_order(shopify_order)
        validation_service = Shopify::Import::OrderValidator.new(
          shopify_order: shopify_order
        )

        validation_response = validation_service.perform

        unless validation_response
          msg = "Could not create order ##{shopify_order.id} for "\
            "retailer: #{@retailer.domain} due to: #{validation_service.errors}\n"
          @errors << msg
          puts "#{@errors}".red
          return nil
        end

        validation_service
      end
    end
  end
end
