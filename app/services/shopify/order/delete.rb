module Shopify
  module Order
    class Deleter < Base
      require 'open-uri'

      def perform(retailer_shopify_identifier)
        begin
          local_order = Spree::Order.find_by(retailer_shopify_identifier: retailer_shopify_identifier)
          if local_order.present?

            @logs << "Deleting Order #{local_order.retailer_shopify_identifier}.\n"

            local_order.delete

            @logs << "Order #{local_order.retailer_shopify_identifier} deleted.\n"
          end
          true
        rescue => e
          @errors << "#{e} \n"
          @error = true
          return false
        end
      end
    end
  end
end
