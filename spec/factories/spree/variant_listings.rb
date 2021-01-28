# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :spree_variant_listing, class: 'Spree::VariantListing' do
    association :retailer, factory: :spree_retailer
    # association :supplier, factory: :spree_supplier
    association :variant, factory: :spree_variant
    # association :retail_connection, factory: :spree_retail_connection
    # association :product_listing, factory: :spree_product_listing
  end
end
