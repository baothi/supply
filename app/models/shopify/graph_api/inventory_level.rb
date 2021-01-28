module Shopify
  module GraphAPI
    class InventoryLevel < Base
      include InventoryQueries

      def update(inventory_item_adjustments, location_id)
        graph_query(INVENTORY_BULK_ADJUST_QUERY, variables: {
            inventoryItemAdjustments: inventory_item_adjustments,
            locationId: location_id
        })
      end
    end
  end
end
