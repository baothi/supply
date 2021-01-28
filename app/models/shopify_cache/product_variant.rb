# Used to represent the original variant embedded in Product.
class ShopifyCache::ProductVariant
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :product, class_name: 'ShopifyCache::Product', inverse_of: :variant

  include ShopifyCache::ProductVariants::Fields
end
