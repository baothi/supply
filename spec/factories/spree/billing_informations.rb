# FactoryBot.define do
#   factory :spree_billing_information, class: Spree::BillingInformation do
#     supplier factory: :spree_supplier
#     last_four_digits Faker::Number.number(4)
#     exp_month Faker::Number.between(1, 12)
#     exp_year Faker::Number.between(2018, 2020)
#     stripe_customer_identifier Faker::Internet.password(10)
#     card_type 'Visa'
#   end
# end
