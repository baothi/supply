module Spree
  class ResellerAgreement < ApplicationRecord
    belongs_to :supplier
    belongs_to :retailer
  end
end
