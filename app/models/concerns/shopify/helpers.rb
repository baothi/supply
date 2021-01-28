# Used by VariantListing.
module Shopify::Helpers
  include Spree::Calculator::PriceCalculator
  extend ActiveSupport::Concern

  included do
  end

  # Used for dealing with Shopify DTG
  def translate_shopify_inventory_amount(shopify_variant)
    return 100 if shopify_variant.inventory_management.nil? # return 100 as inventory is not tracked

    shopify_variant.inventory_quantity
  end

  # def price(shopify_product)
  #   prices = shopify_product.variants.map(&:price).map(&:to_f)
  #   prices.min
  # end

  # def return_msrp_price(shopify_variant)
  #   msrp_price = if shopify_variant.compare_at_price.present?
  #                  shopify_variant.compare_at_price
  #                else
  #                  shopify_variant.price * 1.4
  #                end
  #   msrp_price
  # end

  # def set_basic_cost(price)
  #   price
  # end

  def product_price(shopify_product, supplier)
    prices = shopify_product.variants.map(&:price).map(&:to_f)
    price = prices.min
    price(price, supplier)
  end

  def set_basic_cost(price, supplier)
    calc_cost_price(price, supplier.instance_type, supplier.default_markup_percentage)
  end

  def price(price, supplier)
    calc_price(price, supplier.instance_type, supplier.default_markup_percentage)
  end

  def return_msrp_price(shopify_variant, supplier)
    price = shopify_variant.price
    compare_at_price = shopify_variant.compare_at_price
    calc_msrp_price(price,
                    compare_at_price,
                    supplier.instance_type,
                    supplier.default_markup_percentage)
  end

  def original_supplier_sku(shopify_variant, supplier)
    shopify_variant.send(supplier.shopify_product_unique_identifier)&.upcase
  end

  def platform_supplier_sku(shopify_variant, supplier)
    "#{original_supplier_sku(shopify_variant, supplier)}-#{supplier.brand_short_code}"
  end
end
