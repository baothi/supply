FactoryBot.define do
  factory :spree_supplier, class: 'Spree::Supplier' do
    name { Faker::Company.name }
    email { Faker::Internet.email }
    website { Faker::Internet.url }
    phone_number { Faker::Number.number(digits: 10) }
    facebook_url { Faker::Internet.user_name(specifier: 5..12) }
    instagram_url { Faker::Internet.user_name(specifier: 5..12) }
    instance_type { 'wholesale' }
    shopify_url { Faker::Internet.url }
    # ecommerce_platform Spree::SupplierApplication.ecommerce_platforms.keys.sample.to_s
    # commission_type Spree::Supplier.commission_types.keys.sample
    # supplier_commission 50.00
    # retailer_commission 50.00
    tax_identifier_type { %w(ssn ein) }
    tax_identifier { Faker::Number.number(digits: 10) }
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

    after(:create) do |supplier|
      FactoryBot.create(:spree_team_member, teamable: supplier, role_name: 'test_supplier_owner')
    end

    factory :spree_supplier_without_access_granted do
      access_granted_at { nil }
    end

    factory :spree_supplier_not_yet_onboarded do
      access_granted_at { nil }
      onboarding_session_at { nil }
      scheduled_onboarding_at { nil }
      completed_onboarding_at { nil }
    end
  end
end
