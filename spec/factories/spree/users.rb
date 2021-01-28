FactoryBot.define do
  factory :spree_user, class: Spree.user_class do
    email { Faker::Internet.email }
    shopify_url { Faker::Internet.url }
    password { 'password' }
    last_name { Faker::Name.last_name }
    first_name { Faker::Name.first_name }
    confirmed_at { DateTime.now }
    confirmation_token { Faker::Code.ean }
    # phone_number { Faker::PhoneNumber.cell_phone }
  end
end
