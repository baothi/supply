# Caveat: location_id - Refers to encoded IDs for GraphQL
# e.g.  gid://shopify/Location/21230321723
# TODO: Use better name e.g. graphql_encoded_location_id
module Shopify
  module Product
    class BulkInventoryUpdater
      attr_accessor :retailer, :ro

      def initialize(opts = {})
        validate opts

        @retailer = Spree::Retailer.find(opts[:retailer_id])
      end

      def validate(opts)
        raise 'Retailer id is required' unless opts[:retailer_id].present?
      end

      def perform
        @ro = ResponseObject.success_response_object('N/A')
        begin
          retailer.initialize_shopify_session!
          location_id = Shopify::GraphAPI::Base.encode_id(
            retailer.default_location_shopify_identifier, :Location
          )

          # Get all current inventory adjustments
          iterate_through_inventory_levels_at_location(
            retailer.default_location_shopify_identifier,
            location_id
          )
          retailer.destroy_shopify_session!
        rescue => e
          ro.message = " #{e}\n"
          ro.fail!
        end
        ro
      end

      def perform_adjustment(inventory_item_adjustments:, location_id:)
        # process bulk adjustments in batches of 100 because Shopify's Graph API says
        # Quantity can't be adjusted for more than 100 items.

        inventory_item_adjustments.each_slice(100) do |inventory_adjustments_batch|
          # fetch latest quantities with available delta of zero.
          inventory_level = Shopify::GraphAPI::InventoryLevel.new(retailer)
          result = inventory_level.update(inventory_adjustments_batch, location_id)
          calculated_inventory_adjustments = calculate_inventory_adjustments(result)

          # update with calculated inventory adjustments in bulk
          result = inventory_level.update(calculated_inventory_adjustments, location_id)

          unless result.original_hash['data'].present?
            raise I18n.t('products.error.bulk_inventory_update_issue',
                         location_id: location_id,
                         retailer_id: retailer&.id,
                         retailer_name: retailer&.name)
          end
        end
      end

      private

      # calculate inventory adjustments from latest quantities at shopify
      def calculate_inventory_adjustments(result)
        calculated_inventory_adjustments = []

        data = result.original_hash['data']['inventoryBulkAdjustQuantityAtLocation']
        shopify_inventory_levels = data['inventoryLevels']

        shopify_inventory_levels.each do |level|
          available_quantity = level['available'].to_i
          # shopify_variant_id = Shopify::GraphAPI::Base.decode_id(
          #   level['item']['variant']['id'], :ProductVariant
          # )

          # Use the SKU to determine the quantity
          platform_supplier_sku = level['item']['variant']['sku']

          next if platform_supplier_sku.blank?

          available_delta =
            quantity_to_syndicate(retailer, platform_supplier_sku) - available_quantity

          unless available_delta.zero?
            calculated_inventory_adjustments << {
                inventoryItemId: level['item']['id'],
                availableDelta: available_delta
            }
          end
        end
        calculated_inventory_adjustments
      end

      # prepare inventory item adjustments list to fetch initial quantities with availableDelta zero
      def inventory_item_adjustments(inventory_levels:)
        inventory_item_ids = inventory_levels.map(&:inventory_item_id)
        inventory_item_ids.uniq.map do |id|
          {
              inventoryItemId: Shopify::GraphAPI::Base.encode_id(id, :InventoryItem),
              availableDelta: 0
          }
        end
      end

      # TODO: Move to ShopifyCache
      def get_inventory_levels(shopify_location_identifier:)
        ShopifyAPIRetry.retry(3) do
          ShopifyAPI::InventoryLevel.find(
            :all,
            params: {
                location_ids: shopify_location_identifier,
                limit: 250,
            }
          )
        end
      end

      def iterate_through_inventory_levels_at_location(shopify_location_identifier, location_id)
        # provide comma-separated list of location ids if retailer has multiple locations
        page = 1
        inventory_levels = get_inventory_levels(
          shopify_location_identifier: shopify_location_identifier
        )
        process_inventory_levels(inventory_levels, location_id)

        while inventory_levels.next_page?
          page += 1
          inventory_levels = inventory_levels.fetch_next_page
          process_inventory_levels(inventory_levels, location_id)

          # Protect this endpoint from doing too much work.
          if page > 20
            Rollbar.error('Cannot request more than 20 pages of InventoryLevels',
                          retailer_id: retailer&.id,
                          retailer: retailer&.name,
                          shopify_location_identifier: shopify_location_identifier)
            return []
          end

          sleep 1 if (page % 5).zero?
        end
      end

      def process_inventory_levels(inventory_levels, location_id)
        # Get the current levels & create the query to execute adjustments
        inventory_item_adjustments =
          inventory_item_adjustments(inventory_levels: inventory_levels)

        return if inventory_item_adjustments.empty?

        # Perform adjustments
        perform_adjustment(
          inventory_item_adjustments: inventory_item_adjustments,
          location_id: location_id
        )
      end

      def syndicated_inventory_amount(variant, retailer)
        return 0 if variant.discontinued? || variant.product&.discontinued?

        variant.available_quantity(retailer: retailer)
      end

      def quantity_to_syndicate(retailer, platform_supplier_sku)
        Spree::Variant.available_quantity(
          retailer: retailer,
          platform_supplier_sku: platform_supplier_sku
        )
      end
    end
  end
end
