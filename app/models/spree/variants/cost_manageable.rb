module Spree::Variants::CostManageable
  extend ActiveSupport::Concern

  include SizeNameable

  included do
    before_save :update_variant_costs_from_master
  end

  def update_variant_costs_from_master
    variant_cost = Spree::VariantCost.find_by(supplier_id: self.supplier_id,
                                              sku: self.original_supplier_sku)

    return if variant_cost.nil?

    self.price_management = Spree::VariantCost::MASTER_SHEET
    self.cost_price = variant_cost.cost
    self.price = variant_cost.cost
    self.msrp_price = variant_cost.msrp
    self.map_price = variant_cost.minimum_advertised_price
  end
end
