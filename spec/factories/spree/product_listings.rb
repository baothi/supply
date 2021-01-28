# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :spree_product_listing, class: 'Spree::ProductListing' do
    shopify_identifier { Faker::Code.ean }
    # association :retailer, factory: :spree_retailer
    # association :supplier, factory: :spree_supplier

    association :product, factory: :spree_product
    # association :retail_connection, factory: :spree_retail_connection
  end
end
