module Spree::LineItems::Dscoable
  extend ActiveSupport::Concern
  def to_dsco_export_row
    test_flag = if ENV['DSCO_TEST_FLAG'].present?
                  ENV['DSCO_TEST_FLAG'].to_i
                elsif Rails.env.production?
                  0
                else
                  1
                end
    address = order.shipping_address
    [
      order.number, line_item_number.to_i, original_supplier_sku, quantity, cost_price,
      line_item_shipping_cost.to_f, address.firstname, address.lastname, address.address1,
      address.address2, address.city, address.name_of_state, address.zipcode, address.country_iso,
      address.phone, order.retailer_email, 'USPS', 'Priority Mail', test_flag, order.number
    ]
  end
end
