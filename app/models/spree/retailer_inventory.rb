module Spree
  class RetailerInventory < ApplicationRecord
    belongs_to :retailer, class_name: 'Spree::Retailer'

    validates_presence_of :retailer
  end
end
