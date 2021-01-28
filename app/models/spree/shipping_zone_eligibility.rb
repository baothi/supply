module Spree
  class ShippingZoneEligibility < ApplicationRecord
    belongs_to :supplier, class_name: 'Spree::Supplier'
    belongs_to :zone, class_name: 'Spree::Zone'

    validates :supplier, :zone, presence: true
  end
end
