# require 'spree/testing_support/factories'
FactoryBot.define do
  factory :spree_product, class: Spree::Product do
    sequence(:name) { |n| "Product ##{n} - #{Kernel.rand(9999)}" }
    price { Faker::Number.decimal(l_digits: 2) }
    # cost_price Faker::Number.decimal 2
    sku { Faker::Internet.password }
    supplier factory: :spree_supplier
    available_on { Time.now }
    discontinue_on { nil }
    shipping_category do |_r|
      Spree::ShippingCategory.first || FactoryBot.create(:spree_shipping_category_with_method)
    end

    factory :spree_product_in_stock do
      before(:create) { create(:spree_stock_location) if Spree::StockLocation.count.zero? }

      after :create do |product|
        product.master.stock_items.first.adjust_count_on_hand(10)

        create_list(:variant, 5, product_id: product.id, discontinue_on: nil)
        product.reload.variants.each do |variant|
          variant.update_variant_stock(10)
          variant.update(original_supplier_sku: Faker::Code.ean, supplier_id: product.supplier_id)
        end
      end
    end
  end
end
