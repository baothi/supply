# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_variant, class: ShopifyCache::Variant do
    sequence :id do |n|
      "123456789#{n}".to_i
    end
    sku { Faker::Internet.password.upcase }
    barcode { Faker::Code.ean.upcase }
    shopify_url { 'test.myshopify.com' }
    inventory_management { 'shopify' }

    product_published_at { '2018-07-10T15:20:37-04:00' }
    product_deleted_at { nil }

    product_id { Faker::Number.number(digits: 10) }

    factory :retailer_shopify_cache_variant do
      role { 'retailer' }
    end

    factory :supplier_shopify_cache_variant do
      role { 'supplier' }
    end

    factory :shopify_cache_variant_with_negative_quantity do
      inventory_quantity { -4 }
      old_inventory_quantity { -4 }
    end

    factory :shopify_cache_variant_with_100_quantity do
      inventory_quantity { 100 }
      old_inventory_quantity { 100 }
    end
  end
end