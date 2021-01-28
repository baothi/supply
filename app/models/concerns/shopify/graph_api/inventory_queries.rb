module Shopify
  module GraphAPI
    module InventoryQueries
      extend ActiveSupport::Concern

      included do
        INVENTORY_BULK_ADJUST_QUERY = Shopify::GraphAPI::QUERY.parse <<-'GRAPHQL'
          mutation($inventoryItemAdjustments: [InventoryAdjustItemInput!]!, $locationId: ID!) {
            inventoryBulkAdjustQuantityAtLocation(inventoryItemAdjustments: $inventoryItemAdjustments, locationId: $locationId) {
              inventoryLevels {
                id
                available
                item {
                  id
                  variant {
                    id
                    sku
                  }
                }
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL
      end
    end
  end
end
