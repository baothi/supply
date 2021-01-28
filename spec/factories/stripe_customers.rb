FactoryBot.define do
  factory :stripe_customer, class: 'StripeCustomer' do
    strippable factory: :spree_retailer
    sequence(:customer_identifier) { |n| "cus_0000#{n}" }
    currency { 'usd' }
  end
end
