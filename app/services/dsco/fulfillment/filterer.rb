module Dsco
  module Fulfillment
    class Filterer
      attr_accessor :dsco_line_items
      def initialize(dsco_line_items)
        @dsco_line_items = dsco_line_items
      end

      def perform
        dsco_line_items.select { |dsco_line_item| valid_line_item?(dsco_line_item) }
      end

      def valid_line_item?(dsco_line_item)
        fulfilled?(dsco_line_item) && supply_line_item?(dsco_line_item)
      end

      def supply_line_item?(dsco_line_item)
        # variant = Spree::Variant.find_by(dsco_identifier: dsco_line_item.dsco_item_id)
        variant = Spree::Variant.find_by(original_supplier_sku: dsco_line_item.line_item_sku&.upcase)
        order = Spree::Order.find_by(number: dsco_line_item.po_number)
        variant.present? && order.present?
      end

      def fulfilled?(dsco_line_item)
        dsco_line_item.package_tracking_number.present? &&
          dsco_line_item.dsco_order_status == 'shipped'
      end
    end
  end
end
