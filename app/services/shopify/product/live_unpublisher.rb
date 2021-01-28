module Shopify
  module Product
    class LiveUnpublisher
      def initialize(opts = {})
        validate(opts)
      end

      def validate(opts)
        raise 'Product Required' if opts[:product].nil?

        @product = opts[:product]

        raise 'Listing Required' if opts[:product_listing].nil?

        @product_listing = opts[:product_listing]
      end

      def perform
        ro = ResponseObject.success_response_object('N/A')
        begin
          retailer = @product_listing.retailer
          retailer.initialize_shopify_session!

          shopify_product = CommerceEngine::Shopify::Product.find(
            @product_listing.shopify_identifier
          )
          shopify_product.published_at = nil
          shopify_product.save!
          ro.message = 'Success'

          retailer.destroy_shopify_session!
        rescue => e
          ro.message = " #{e}\n"
          ro.fail!
        end
        ro
      end
    end
  end
end
