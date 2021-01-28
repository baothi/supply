# FactoryBot.define do
#   factory :spree_supplier_application_coupon, class: 'Spree::SupplierApplicationCoupon' do
#     code { Faker::Commerce.promotion_code }
#     value_type Spree::SupplierApplicationCoupon.value_types['percent']
#     coupon_value { rand(100) }
#     retailer factory: :spree_retailer

#     # coupon_value 50
#     # internal_identifier Faker::Number.hexadecimal(8)
#   end
# end
