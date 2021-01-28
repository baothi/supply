# FactoryBot.define do
#   factory :spree_supplier_application_draft, class: 'Spree::SupplierApplicationDraft' do
#     supplier_name Faker::Company.name
#     email Faker::Internet.email
#     website Faker::Internet.url
#     first_name Faker::Name.first_name
#     last_name Faker::Name.last_name
#     phone_number Faker::PhoneNumber.cell_phone
#     facebook_url Faker::Internet.user_name(5..12, [])
#     instagram_url Faker::Internet.user_name(5..12, [])
#     ecommerce_platform Spree::SupplierApplication.ecommerce_platforms.keys.sample.to_s
#     application_fee Faker::Number.decimal(2, 1).to_f.round
#     retailer factory: :spree_retailer
#   end
# end
