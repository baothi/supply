# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :shopify_cache_product_variant, class: ShopifyCache::ProductVariant do
    sequence :id do |n|
      "123456789#{n}".to_i
    end
    sku { Faker::Internet.password.upcase }
    barcode { Faker::Code.ean.upcase }
    # shopify_url { 'test.myshopify.com' }
    inventory_management { 'shopify' }

    # factory :retailer_shopify_cache_product_variant do
    #   role { 'retailer' }
    # end
    #
    # factory :supplier_shopify_cache_product_variant do
    #   role { 'supplier' }
    # end

    factory :shopify_cache_product_variant_with_negative_quantity do
      inventory_quantity { -4 }
      old_inventory_quantity { -4 }
    end

    factory :shopify_cache_product_variant_with_100_quantity do
      inventory_quantity { 100 }
      old_inventory_quantity { 100 }
    end
  end
end
