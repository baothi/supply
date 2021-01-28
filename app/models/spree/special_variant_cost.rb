class Spree::SpecialVariantCost < ApplicationRecord
  include Unremovable

  belongs_to :supplier, class_name: 'Spree::Supplier'
  belongs_to :retailer, class_name: 'Spree::Retailer'

  validates_presence_of :sku,
                        :msrp,
                        :cost,
                        :supplier

  before_validation :upcase_sku
  validate :msrp_greater_than_cost

  def upcase_sku
    self.sku = self.sku&.upcase
  end

  def msrp_greater_than_cost
    errors.add(:msrp, 'Must be greater than cost') if msrp <= cost
    errors.add(:cost, 'Must be less than MSRP') if msrp < cost
  end
end
