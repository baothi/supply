# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :spree_product_export_process, class: 'Spree::ProductExportProcess' do
    association :retailer, factory: :spree_retailer
    association :product, factory: :spree_product
  end
end
