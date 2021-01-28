# FactoryBot.define do
#   factory :old_supplier_application, class: 'OldSupplierApplication' do
#     #   association :retailer, factory: :spree_retailer
#     brand_name Faker::Company.name
#     first_name Faker::Name.first_name
#     last_name Faker::Name.last_name
#     email { Faker::Internet.email }
#     website Faker::Internet.url
#     phone_number Faker::PhoneNumber.cell_phone
#     facebook_url Faker::Internet.user_name(5..12, [])
#     instagram_url Faker::Internet.user_name(5..12, [])
#     ecommerce_platform Spree::SupplierApplication.ecommerce_platforms.keys.sample.to_s
#   end
# end
