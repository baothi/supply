# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_event, class: ShopifyCache::Event do
    sequence :subject_id do |n|
      "123456789#{n}".to_i
    end
    processed_at { nil }
    created_at { '2018-07-10T15:20:37-04:00' }
    subject_type { 'Product' }
    verb { 'destroy' }
    shopify_url { 'test.myshopify.com' }
    role { 'supplier' }

    factory :processed_shopify_cache_event do
      processed_at { '2018-07-10T15:20:37-04:00' }
    end

    factory :unprocessed_shopify_cache_event do
      processed_at { nil }
    end
  end
end
