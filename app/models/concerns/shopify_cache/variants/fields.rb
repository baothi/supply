module ShopifyCache::Variants::Fields
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

    field :role, type: String
    field :shopify_url, type: String

    field :lower_sku, type: String
    field :lower_barcode, type: String

    # These are manufactured fields by us to help with querying.
    field :product_id, type: Integer
    # We use string to keep with Shopify convention for date
    field :product_deleted_at, type: String
    field :product_published_at, type: String

    validates_presence_of :product_id
    validates_presence_of :shopify_url
    validates_presence_of :role
  end
end
