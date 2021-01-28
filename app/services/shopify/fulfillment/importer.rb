module Shopify
  module Fulfillment
    class Importer < Base
      def perform(order_id)
        @order = Spree::Order.find_by(internal_identifier: order_id)
        begin
          shopify_id = @order.supplier_shopify_identifier
          @shopify_order = ShopifyAPIRetry.retry(5) { ShopifyAPI::Order.find(shopify_id) }
          return false unless @shopify_order.present?

          @shopify_line_items = Shopify::Fulfillment::Filterer.new(
            order: @shopify_order,
            kind: 'import'
          ).perform

          return unless @shopify_line_items.present? && @shopify_line_items.compact.present?

          @shopify_line_items.each do |shopify_line_item|
            local_line_item = get_local_line_item(shopify_line_item)
            tracking_number = get_tracking_number(shopify_line_item)
            local_line_item.fulfill_shipment(tracking_number) if tracking_number
          end
          @order.reload
          @order.shipment_state = @order.updater.update_shipment_state
          @order.save!
          true
        rescue => e
          @errors << " #{e}\n"
          false
        end
      end

      def get_local_line_item(shopify_line_item)
        begin
          # First find local variant
          local_variant = Spree::Variant.find_by_shopify_identifier(shopify_line_item.variant_id)
          # TODO: Email Supplier/Retailer if it can't find it.

          raise 'Variant is unavailable locally. Cannot fulfill' if
              local_variant.nil?

          local_line_item = @order.line_items.where(
            variant_id: local_variant.id
          ).first

          raise 'Unable to find corresponding line item. Cannot fulfill' if
              local_line_item.nil?

          local_line_item
        rescue => e
          @errors << "#{e}\n"
        end
      end

      def get_tracking_number(shopify_line_item)
        fulfillments = @shopify_order.fulfillments
        fulfillments.each do |f|
          line_items_ids = f.line_items.map(&:id)
          return f.tracking_number if line_items_ids.include?(shopify_line_item.id)
        end
      end
    end
  end
end
