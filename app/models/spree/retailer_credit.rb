class Spree::RetailerCredit < ApplicationRecord
  belongs_to :retailer, class_name: 'Spree::Retailer'

  def has_supplier_credit?
    by_supplier.try(:positive?)
  end

  def has_hingeto_credit?
    by_hingeto.try(:positive?)
  end

  def total_available_credit
    (by_supplier || 0) + (by_hingeto || 0)
  end

  def has_credit?
    total_available_credit.positive?
  end
end
