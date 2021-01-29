class MigrateShippingCosts < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::Shipment.reset_column_information
      Spree::Shipment.find_each do |shipment|
        shipment.per_item_cost = shipment.cost
        shipment.save!
      end
    rescue => e
      puts "Error copying Shipment: #{e.message}".red
    end
  end

  def down

  end
end
