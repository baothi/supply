module Spree::Orders::Constants
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    page_numbers = [10, 25, 50, 100].freeze
    Dropshipper::ConstantsHelper.create_klass_constant(
      'Spree::Order', 'PAGE_QUANTITY_OPTIONS', page_numbers
    )
  end

  SUPPLIER_STATUS_FILTERS = %i(
    all partially_fulfilled late fulfilled unfulfilled cancelled
  ).freeze

  ADMIN_STATUS_FILTERS = %i(
    all paid unpaid fulfilled unfulfilled risky late due_soon due_in_24_hours international
  ).freeze

  RETAILER_STATUS_FILTERS = %i(all paid unpaid fulfilled unfulfilled risky international).freeze
end
