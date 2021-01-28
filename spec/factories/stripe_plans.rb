FactoryBot.define do
  factory :stripe_plan do
    sequence(:plan_identifier) { |n| "hingeto-plan-#{n}" }
    name { plan_identifier.try(:humanize) }
    amount { 1000 }
    currency { 'usd' }
    interval { 'month' }
    interval_count { 1 }
    description { "Description for #{name}" }
  end
end
