FactoryBot.define do
  factory :spree_retail_connection, class: 'Spree::RetailConnection' do
    association :retailer, factory: :spree_retailer
    association :supplier, factory: :spree_supplier
  end
end
