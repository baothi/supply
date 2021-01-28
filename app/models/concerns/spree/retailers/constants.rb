module Spree::Retailers::Constants
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    ROLES = %w(retailer_owner retailer_admin retailer_merchandiser retailer_finance
               retailer_marketing retailer_legal).freeze

    Dropshipper::ConstantsHelper.create_constant_from_collection('Spree::Retailer',
                                                                 'RETAILER_ROLES',
                                                                 ROLES)
  end
end
