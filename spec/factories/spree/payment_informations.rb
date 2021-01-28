# FactoryBot.define do
#   factory :spree_payment_information, class: 'Spree::PaymentInformation' do
#     payee_name Faker::Name.name
#     association :supplier, factory: :spree_supplier

#     trait :wire do
#       payment_preference 'wire'
#       bank_name Faker::Bank.name
#       bank_account_type { %w(Savings Checking Other).sample }
#       bank_account_number Faker::Number.number(10)
#       bank_routing_number Faker::Number.number(10)
#     end

#     trait :check do
#       payment_preference 'check'
#       street_address Faker::Address.street_address
#       line2 Faker::Address.building_number
#       city Faker::Address.city
#       state Faker::Address.state
#       country 'USA'
#       postal_code Faker::Address.postcode
#     end
#   end
# end
