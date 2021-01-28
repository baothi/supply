FactoryBot.define do
  factory :stripe_card do
    stripe_customer factory: :stripe_customer
    sequence(:card_identifier) { |n| "card_0000#{n}" }
    country { 'US' }
    customer_identifier { stripe_customer.try(:customer_identifier) }
    exp_month { 3.years.from_now.month }
    exp_year { 3.years.from_now.year }
    last4 { '4242' }
    name { 'My card' }
  end
end
