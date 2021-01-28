# require 'spree/testing_support/factories'
FactoryBot.define do
  # sequence(:random_float) { BigDecimal.new("#{rand(200)}.#{rand(99)}") }

  factory :spree_variant, class: Spree::Variant do
    price { 19.99 }
    cost_price { 17.00 }
    msrp_price { 17.00 }
    original_supplier_sku { Faker::Code.ean }
    sku    { Faker::Code.ean }
    platform_supplier_sku    { Faker::Code.ean }

    weight { generate(:random_float) }
    height { generate(:random_float) }
    width  { generate(:random_float) }
    depth  { generate(:random_float) }
    is_master { 0 }
    track_inventory { true }

    product { |p| p.association(:spree_product) }
    supplier { product.supplier if product }

    option_values { [create(:option_value)] }

    # ensure stock item will be created for this variant
    before(:create) { create(:spree_stock_location) if Spree::StockLocation.count.zero? }

    # after(:build)  { |v| v.upc = v.sku  if v.upc.blank? }

    factory :variant_with_size_and_color do
      after(:create) do |v|
        option_type_size  = FactoryBot.create(:option_type_size)
        option_type_color = FactoryBot.create(:option_type_color)

        red = FactoryBot.create(:spree_option_value,
                                option_type: option_type_color,
                                name: 'red',
                                presentation: 'Red')
        xl = FactoryBot.create(:spree_option_value,
                               option_type: option_type_size,
                               name: 'xl',
                               presentation: 'XL')

        # Create Join Table Values
        FactoryBot.create(:spree_option_value_variant, option_value: red, variant: v)
        FactoryBot.create(:spree_option_value_variant, option_value: xl, variant: v)

        v.reload
      end

      # supplier_color_code 'red'
      # supplier_size_code 'xl'
    end

    factory :spree_variant_with_quantity do
      transient do
        quantity { 10 }
      end
      before(:create) { create(:spree_stock_location) if Spree::StockLocation.count.zero? }

      after :create do |variant, evaluator|
        variant.stock_items.first.adjust_count_on_hand(evaluator.quantity)
      end
    end

    # factory :variant do
    #   # on_hand 5
    #   product { |p| p.association(:product) }
    # end
    #
    # factory :master_variant do
    #   is_master 1
    # end
    #
    factory :on_demand_spree_variant do
      track_inventory { false }

      factory :on_demand_spree_master_variant do
        is_master { 0 }
      end
    end
  end
end
