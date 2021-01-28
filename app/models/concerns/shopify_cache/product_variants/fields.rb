module ShopifyCache::ProductVariants::Fields
  extend ActiveSupport::Concern

  included do
    field :title, type: String
    field :price, type: String
    field :sku, type: String
    field :position, type: Integer
    field :inventory_policy, type: String
    field :compare_at_price, type: String
    field :fulfillment_service, type: String
    field :inventory_management, type: String
    field :option1, type: String
    field :option2, type: String
    field :option3, type: String

    field :created_at, type: String
    field :updated_at, type: String

    field :barcode, type: String
    field :inventory_quantity, type: Integer
    field :old_inventory_quantity, type: Integer

    # field :role, type: String
    # field :shopify_url, type: String
  end
end
