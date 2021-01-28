module Shopify
  module Product
    class LiveInventoryUpdater
      attr_accessor :retailer, :variant, :variant_listing, :ro
      def initialize(opts = {})
        validate(opts)
      end

      def validate(opts)
        raise 'Variant Required' if opts[:variant].nil?

        @variant = opts[:variant]

        raise 'Listing Required' if opts[:variant_listing].nil?

        @variant_listing = opts[:variant_listing]
      end

      def perform
        @ro = ResponseObject.success_response_object('N/A')
        begin
          @retailer = variant_listing.retailer
          retailer.initialize_shopify_session!

          shopify_variant = ShopifyAPIRetry.retry (3) do
            ShopifyAPI::Variant.find(variant_listing.shopify_identifier)
          end

          set_inventory(shopify_variant) ? ro.message = 'Success' : ro.fail!

          retailer.destroy_shopify_session!
        rescue => e
          ro.message = " #{e}\n"
          ro.fail!
        end
        ro
      end

      def set_inventory(shopify_variant)
        begin
          inventory_item_id = shopify_variant.inventory_item_id
          locations = ShopifyAPIRetry.retry(5) { ShopifyAPI::Location.all }
          location_ids = locations.map(&:id).join(',')

          params = {
            inventory_item_ids: inventory_item_id,
            location_ids: location_ids
          }

          result = ShopifyAPIRetry.retry(3) do
            ShopifyAPI::InventoryLevel.find(:all, params: params)
          end

          raise 'No valid inventory level' unless result.present? && verified?(result, params)

          inventory_level = result.first

          ShopifyAPIRetry.retry(5) { inventory_level.set(syndicated_inventory_amount(variant)) }
          true
        rescue => e
          ro.message = " #{e}\n"
          puts ro.message.red
          ro.fail!
          false
        end
      end

      def syndicated_inventory_amount(variant)
        product = variant.product
        return 0 if product&.discontinued? || variant.discontinued?

        variant.available_quantity
      end

      def verified?(result, params)
        level = result.first
        correct_inventory_item = level.inventory_item_id == params[:inventory_item_ids]
        correct_location = if params[:location_ids].present?
                             level.location_id.to_s == params[:location_ids]
                           else
                             true
                           end
        correct_inventory_item && correct_location
      end
    end
  end
end
