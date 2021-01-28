module Shopify
  module Fulfillment
    class Filterer
      def initialize(opts = {})
        @shopify_order = opts[:order]
        @kind = opts[:kind]
      end

      def perform
        case @kind
        when 'import'
          order_fulfillments = @shopify_order.fulfillments

          if order_fulfillments.present?
            order_fulfillments.map do |f|
              f.line_items if f.tracking_number.present? && f.status == 'success'
            end.flatten
          end
        when 'export'
          @shopify_order.line_items.select(&:shipped?)
        end
      end
    end
  end
end
