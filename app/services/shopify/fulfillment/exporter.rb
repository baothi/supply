module Shopify
  module Fulfillment
    class Exporter
      attr_accessor :retailer, :errors, :logs

      def initialize(opts = {})
        @retailer_id = opts[:retailer_id]
        raise 'Retailer required for fulfillment export' if @retailer_id.nil?

        @retailer = Spree::Retailer.find_by(id: @retailer_id)
        @retailer.init

        @errors = ''
        @logs = ''
      end

      def perform(order_id)
        @order = Spree::Order.find_by(internal_identifier: order_id)
        @retailer = @order.retailer
        begin
          # TODO: We should cache the list of locations on a retailer at some interval
          # & only make a new call when its out of dat
          @shopify_locations = ShopifyAPIRetry.retry(5) { ShopifyAPI::Location.all }

          @shopify_order =
            ShopifyAPIRetry.retry(5) { ShopifyAPI::Order.find(@order.retailer_shopify_identifier) }
          return false unless @shopify_order.present?

          inventory_units = @order.inventory_units
          shipment_groups = group_shipments(inventory_units)
          shipment_groups.each do |tracking, units|
            raw_line_items = units.map(&:line_item)
            grouped_line_items = group_by_fulfillment_service(raw_line_items)
            grouped_line_items.each do |fulfillment_service, line_items|
              fulfill_line_items!(
                fulfillment_service: fulfillment_service,
                line_items: line_items,
                tracking: tracking
              )
            end
          end
        rescue => e
          @errors << " #{e}\n"
          @errors << " #{e.backtrace}\n"
          puts "#{e}".red
          Rollbar.error(e, order_id: @order.internal_identifier, error: 'Fulfillment export error')
          false
        end
      end

      def returning_matching_location(fulfillment_service)
        return @shopify_locations.first.id if fulfillment_service == 'manual'

        @shopify_locations.each do |location|
          puts "Comparing #{location.name} with #{fulfillment_service}".yellow
          return location.id if location.name == fulfillment_service
        end
        nil
      end

      def group_by_fulfillment_service(line_items)
        fulfillment_service_groups =
          line_items.group_by { |li| get_shopify_line_item(li)&.fulfillment_service }
        fulfillment_service_groups.delete(nil)
        fulfillment_service_groups
      end

      def fulfill_line_items!(fulfillment_service:, line_items:, tracking:)
        location_id = returning_matching_location(fulfillment_service)
        shopify_fulfillment = create_shopify_fulfillment(tracking)
        line_items.each do |line_item|
          next if fulfilled?(line_item)

          shopify_fulfillment.line_items << { id: line_item.retailer_shopify_identifier }
        end
        shopify_fulfillment.location_id = location_id
        shopify_fulfillment.prefix_options = { order_id: @shopify_order.id }
        return if shopify_fulfillment.line_items.empty? # This protects full order fulfillments

        ShopifyAPIRetry.retry(5) { shopify_fulfillment.save }

        if fulfillment_service != 'manual'
          ShopifyAPIRetry.retry(5) { shopify_fulfillment.complete }
        end

        # Locally mark Fulfillment as exported

        return unless shopify_fulfillment.id.present?

        ids = shopify_fulfillment.line_items.map(&:id)
        fulfilled_line_items = @order.line_items.where(retailer_shopify_identifier: ids)
        fulfilled_line_items.update_all(fulfillment_sent_to_retailer_at: DateTime.now)
      end

      def get_shopify_line_item(line_item)
        @shopify_order.line_items.each do |shopify_line_item|
          return shopify_line_item if
              line_item.retailer_shopify_identifier&.to_i == shopify_line_item.id
        end
        nil
      end

      def create_shopify_fulfillment(tracking)
        begin
          f = ShopifyAPI::Fulfillment.new(
            order_id: @shopify_order.id,
            notify_customer: @retailer.setting_send_shopify_fulfillment_notice,
            tracking_number: tracking,
            location_id: @retailer.default_location_shopify_identifier
          )
          f.line_items = []
          f
        rescue => e
          @errors << "#{e}\n 47"
          nil
        end
      end

      def group_shipments(inventory_units)
        groups = inventory_units.group_by { |i| i.shipment.tracking }
        groups.delete(nil)
        groups
      end

      def fulfilled?(line_item)
        existing_fulfillments = @shopify_order.fulfillments

        return unless existing_fulfillments.present?

        fulfilled_line_item_ids = existing_fulfillments.map { |f| f.line_items.map(&:id) }.flatten
        fulfilled_line_item_ids.include?(line_item.retailer_shopify_identifier.to_i)
      end
    end
  end
end
