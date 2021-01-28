FactoryBot.define do
  factory :stripe_invoice do
    stripe_customer factory: :stripe_customer
    sequence(:invoice_identifier) { |n| "in_0000#{n}" }
    amount_due { 1000 }
    attempt_count { 1 }
    attempted { true }
    sequence(:charge_identifier) { |n| "ch_0000#{n}" }
    closed { true }
    customer_identifier { stripe_customer.try(:customer_identifier) }
    description { 'Invoice description' }
    paid { true }
    sequence(:subscription_identifier) { |n| "sub_0000#{n}" }
    total { 1000 }

    factory :failed_stripe_invoice do
      paid { false }
      next_payment_attempt { 3.days.from_now }
    end
  end
end
