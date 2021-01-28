FactoryBot.define do
  factory :spree_shipping_category, class: Spree::ShippingCategory do
    sequence(:name) { |n| "ShippingCategory ##{n}" }

    factory :spree_shipping_category_with_method do
      after :create do |category|
        zone = Spree::Zone.find_or_create_by(name: 'United States')

        Spree::ShippingMethod.where(name: category).first_or_create! do |shipping_method|
          code = category.name.gsub(/\s+/, '').upcase
          shipping_method.admin_name = code
          shipping_method.code = code
          shipping_method.service_code = 'FESD'
          calculator = Spree::Calculator::Shipping::CategoryCalculator.new
          calculator.set_preference(:first_item_us, 5)
          calculator.set_preference(:additional_item_us, 2)
          shipping_method.calculator = calculator
          shipping_method.shipping_categories << category
          shipping_method.zones << zone
          shipping_method.save
        end
      end
    end
  end
end
