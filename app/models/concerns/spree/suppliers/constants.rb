module Spree::Suppliers::Constants
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    ROLES = %w(supplier_owner supplier_admin supplier_merchandiser supplier_finance
               supplier_marketing supplier_legal).freeze
    INSTANCE_TYPES = %w(wholesale ecommerce).freeze

    Dropshipper::ConstantsHelper.create_constant_from_collection('Spree::Supplier',
                                                                 'SUPPLIER_ROLES',
                                                                 ROLES)
  end
end
