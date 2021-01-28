FactoryBot.define do
  factory :spree_retailer_credit, class: 'Spree::RetailerCredit' do
    retailer factory: :spree_retailer
    by_supplier { Faker::Number.decimal(2) }
    by_hingeto { Faker::Number.decimal(2) }
  end
end
