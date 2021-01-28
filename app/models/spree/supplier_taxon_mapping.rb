# The purpose of this class is to help with mapping weird values that comes from Suppliers
# for Categories / Licenses and to map them to known values that we want to use
# This will typically be used by Rake Tasks and we'd typically want to know
# the universe of values upfront
#
module Spree
  class SupplierTaxonMapping < ApplicationRecord
    validates :taxon_type, presence: true, allow_nil: false
  end
end
