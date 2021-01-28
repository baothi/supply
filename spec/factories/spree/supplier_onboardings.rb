# FactoryBot.define do
#   factory :spree_supplier_onboarding, class: 'Spree::SupplierOnboarding' do
#     association :supplier_application, factory: :spree_supplier_application

#     payee_name Faker::Name.name

#     factory :contact_information_stage, parent: :spree_supplier_onboarding do
#       tax_identifier Faker::Number.number(9)
#       tax_identifier_type 'ssn'
#       brand_entity_type 'individual'
#       payment_preference 'wire'
#       payee_name_wire Faker::Name.name
#       bank_name Faker::Company.name
#       bank_account_number Faker::Number.number(10)
#       bank_routing_number Faker::Number.number(10)
#     end

#     trait :payment_by_wire do
#       payment_preference 'wire'
#       bank_name Faker::Bank.name
#       bank_account_type { %w(Savings Checking Other).sample }
#       bank_account_number Faker::Number.number(10)
#       bank_routing_number Faker::Number.number(10)
#     end

#     trait :payment_by_check do
#       payment_preference 'check'
#       street_address Faker::Address.street_address
#       line2 Faker::Address.building_number
#       city Faker::Address.city
#       state Faker::Address.state
#       country 'USA'
#       postal_code Faker::Address.postcode
#     end

#     retailer factory: :spree_retailer
#     internal_identifier Faker::Internet.password
#   end
# end
