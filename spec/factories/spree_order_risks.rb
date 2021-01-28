FactoryBot.define do
  factory :spree_order_risk, class: 'Spree::OrderRisk' do
    shopify_identifier { 1 }
    cause_cancel { false }
    display { false }
    shopify_order_id { 1 }
    message { 'MyString' }
    recommendation { 'MyString' }
    score { '9.99' }
    source { 'MyString' }
    order { nil }
  end
end
