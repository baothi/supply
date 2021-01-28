# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_product, class: ShopifyCache::Product do
    sequence :id do |n|
      "123456789#{n}".to_i
    end
    handle { 'random-handle' }
    vendor { 'random-vendor' }
    variants    do
      [FactoryBot.build(:shopify_cache_product_variant),
       FactoryBot.build(:shopify_cache_product_variant)]
    end
    shopify_url { 'test.myshopify.com' }

    role { 'supplier' }
    published_at { '2018-07-10T15:20:37-04:00' }
    updated_at { '2018-07-10T15:20:37-04:00' }
    created_at { '2018-07-10T15:20:37-04:00' }
    deleted_at { nil }

    factory :retailer_shopify_cache_product do
      role { 'retailer' }
    end

    factory :shopify_cache_product_with_negative_quantity do
      variants    do
        [FactoryBot.build(:shopify_cache_product_variant_with_negative_quantity),
         FactoryBot.build(:shopify_cache_product_variant_with_negative_quantity)]
      end
    end

    factory :shopify_cache_product_with_100_quantity do
      variants    do
        [FactoryBot.build(:shopify_cache_product_variant_with_100_quantity),
         FactoryBot.build(:shopify_cache_product_variant_with_100_quantity)]
      end
    end

    factory :shopify_cache_product_marked_as_deleted do
      deleted_at { '2018-07-10T15:20:37-04:00' }
    end
  end
end
