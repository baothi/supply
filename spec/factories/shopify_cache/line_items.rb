# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_line_item, class: ShopifyCache::LineItem do
    title { 'test' }
    quantity { 2 }
    price { 12 }
    sku { Faker::Code.ean }
  end
end
