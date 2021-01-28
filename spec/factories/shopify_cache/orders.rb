# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_order, class: ShopifyCache::Order do
    sequence :id do |n|
      "123456789#{n}".to_i
    end
    email { 'test@google.com' }
    line_items    do
      [FactoryBot.build(:shopify_cache_line_item),
       FactoryBot.build(:shopify_cache_line_item)]
    end
    num_line_items { 2 }
    shopify_url { 'test.myshopify.com' }
    role { 'supplier' }
    updated_at { '2018-07-10T15:20:37-04:00' }
    created_at { '2018-07-10T15:20:37-04:00' }

    factory :retailer_shopify_cache_order do
      role { 'retailer' }
    end
  end
end
