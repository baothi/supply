module Shopify
  module Product
    class Deleter < Base
      require 'open-uri'

      def perform(shopify_identifier)
        begin
          local_product = Spree::Product.find_by(shopify_identifier: shopify_identifier)
          if local_product.present?

            @logs << "Deleting Product #{local_product.name}.\n"

            local_product.update(discontinue_on: Time.now)

            @logs << "Product #{local_product.name} deleted.\n"
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
