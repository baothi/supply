FactoryBot.define do
  factory :stripe_event do
    sequence(:event_identifier) { |n| "env_0000#{n}" }
    event_created { Time.now }
    stripe_eventable factory: :stripe_card
    event_object { nil }
  end
end
