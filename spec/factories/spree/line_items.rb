FactoryBot.define do
  factory :spree_line_item, class: Spree::LineItem do
    quantity { 1 }
    price { BigDecimal('10.00') }
    order factory: :spree_order
    transient do
      association :product
    end
    # variant { product.master }
    variant
    fulfilled_at { nil }
    invalid_fulfilled_at { nil }
    cancelled_at { nil }
  end
end
