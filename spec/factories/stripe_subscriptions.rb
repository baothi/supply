FactoryBot.define do
  factory :stripe_subscription do
    sequence(:subscription_identifier) { |n| "sub_0000#{n}" }
    stripe_customer factory: :stripe_customer
    stripe_plan factory: :stripe_plan
    plan_identifier { stripe_plan.try(:plan_identifier) }
    customer_identifier { stripe_customer.try(:customer_identifier) }
    status { 'active' }
  end
end
