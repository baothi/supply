module DscoOrderExportCsvGenerator
  extend ActiveSupport::Concern
  HEADER_ROW = %w(
    po_number line_item_line_number line_item_sku line_item_quantity line_item_expected_cost
    line_item_shipping_surcharge ship_first_name ship_last_name ship_address_1 ship_address_2
    ship_city ship_region ship_postal ship_country ship_phone ship_email ship_carrier ship_method
    test_flag consumer_order_number
  ).freeze

  def generate_dsco_export_file(order_ids)
    orders = Spree::Order.where(id: order_ids)
    begin
     CSV.generate do |csv|
       csv << HEADER_ROW
       orders.each do |order|
         order.eligible_line_items.each do |line_item|
           begin
             csv << line_item.to_dsco_export_row
           rescue => e
             Rollbar.error(e, line_item: line_item&.id, process: 'Dsco Order Export')
           end
         end
       end
       raw_content = csv.string
       raw_content
     end
   rescue => e
     puts e.to_s
     nil
   end
  end
end
