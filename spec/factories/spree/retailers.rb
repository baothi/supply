FactoryBot.define do
  factory :spree_retailer, class: 'Spree::Retailer' do
    email { Faker::Internet.email }
    name { Faker::Company.name }
    shopify_url { Faker::Internet.url }
    phone_number { Faker::Number.number(digits: 10) }
    access_granted_at { Time.now }

    # Onboarding Related
    onboarding_session_at { Time.now }
    scheduled_onboarding_at { Time.now }
    completed_onboarding_at { Time.now }

    current_stripe_customer_email { Faker::Internet.email }
    current_stripe_customer_identifier { "cus_#{Faker::Code.ean}" }
    current_stripe_subscription_identifier { "sub_#{Faker::Code.ean}" }
    current_stripe_subscription_started_at  { Time.now }
    current_stripe_plan_identifier { "plan_#{Faker::Code.ean}" }

    # We default them to paying

    after(:create) do |retailer|
      FactoryBot.create(:spree_team_member, teamable: retailer, role_name: 'test_retailer_owner')
    end

    factory :spree_retailer_without_access_granted do
      access_granted_at { nil }
    end

    factory :spree_retailer_not_yet_onboarded do
      access_granted_at { nil }
      onboarding_session_at { nil }
      scheduled_onboarding_at { nil }
      completed_onboarding_at { nil }
    end
  end
end
