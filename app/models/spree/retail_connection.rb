module Spree
  class RetailConnection < ApplicationRecord
    belongs_to :retailer
    belongs_to :supplier

    validates :retailer, :supplier, presence: true
  end
end
