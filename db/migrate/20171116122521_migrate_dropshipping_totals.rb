class MigrateDropshippingTotals < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::Order.reset_column_information
      Spree::Order.find_each do |order|
        order.total_shipment_cost = order.shipments.sum(&:per_item_cost).to_f
        order.save!
      end
    rescue => e
      puts "Error Migrating Order Shipment Costs: #{e.message}".red
    end
  end

  def down

  end
end
