# The purpose of this model is to serve as a global index
# of all approved Hingeto Variants
class ShopifyCache::LineItem
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :order, class_name: 'ShopifyCache::Order', inverse_of: :line_item

  field :title, type: String
  field :quantity, type: Integer
  field :price, type: String
  field :sku, type: String
  field :fulfillment_service, type: String
  field :name, type: String
  field :variant_id, type: Integer
  field :variant_title, type: String
end
