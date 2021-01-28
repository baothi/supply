# Used by VariantListing.
module Spree::Variants::FilterScope
  extend ActiveSupport::Concern

  included do
    scope :not_discontinued, -> {
      where('spree_variants.discontinue_on is null')
    }
  end
end
