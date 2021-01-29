class MigrateRetailerIdAndSupplierIdToLineItems < ActiveRecord::Migration[6.0]
  def up
    # For some reason this script didnt' work properly in production. Commenting for now.
    # Spree::LineItem.find_each do |line_item|
    #   begin
    #     next if line_item.retailer_id.present? &&
    #         line_item.supplier_id.present?
    #     order = line_item.order
    #     line_item.retailer_id = order.retailer_id
    #     line_item.supplier_id = order.supplier_id
    #     line_item.save!
    #   rescue => ex
    #     puts "MigrateRetailerIdAndSupplierIdToLineItems: #{ex}".red
    #   end
    # end
  end

  def down
    # Do nothing or update all to be nil?
  end
end
