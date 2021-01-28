module Spree
  class VariantListing < ApplicationRecord
    belongs_to :retailer, class_name: 'Spree::Retailer'
    belongs_to :variant, class_name: 'Spree::Variant'
    belongs_to :product_listing, class_name: 'Spree::ProductListing'

    def self.default_scope
      where(deleted_at: nil)
    end
  end
end
