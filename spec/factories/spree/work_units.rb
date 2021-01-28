# FactoryBot.define do
#   factory :spree_work_unit, class: 'Spree::WorkUnit' do
#     association :retailer, factory: :spree_retailer
#     numeric_only_identifier { Faker::Number.unique.number(5) }
#     sequential_numeric_only_identifier { Faker::Number.unique.number(5) }
#     alpha_numeric_identifier { Faker::Internet.password }
#     alpha_only_identifier { Faker::Lorem.unique.word }
#     workable_type { 'Spree::VariantListing' }
#   end
# end
