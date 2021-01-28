module Spree::Calculator::PriceCalculator
  PLATFORM_MARKUP = 0.07

  def calc_cost_price(price, supplier_instance_type, supplier_markup_percentage)
    case supplier_instance_type
    when 'wholesale'
      price.to_f
    when 'ecommerce'
      (price.to_f / (1 + supplier_markup_percentage)).round(2)
    end
  end

  def calc_msrp_price(price, compare_at_price, supplier_instance_type, supplier_markup_percentage)
    return compare_at_price if compare_at_price.present?

    case supplier_instance_type
    when 'wholesale'
      (price.to_f * (1 + supplier_markup_percentage)).round(2)
    when 'ecommerce'
      price.to_f
    end
  end

  def calc_price(price, supplier_instance_type, supplier_markup_percentage, cp = nil)
    cp ||= calc_cost_price(price, supplier_instance_type, supplier_markup_percentage)
    (cp.to_f * (1 + PLATFORM_MARKUP)).round(2)
  end

  # This method converts numbers like '$5.00' to 5.00
  # It also does a good job of dealing with spaces that often occurs
  # in in file uploads e.g. '$5.33 '
  def convert_currency_string_to_number(currency)
    return nil if currency.blank?

    currency.to_s.gsub(/[$,]/, '').to_f
  end

  module_function :calc_cost_price,
                  :calc_msrp_price,
                  :calc_price,
                  :convert_currency_string_to_number
end
