class CopyUpdatedAtToFulfilledAtForShipments < ActiveRecord::Migration[6.0]
  def up
    Spree::Shipment.all.each do |shipment|
      begin
        shipment.fulfilled_at = shipment.updated_at if shipment.state == 'shipped' &&
            shipment.fulfilled_at.nil?
        shipment.cancelled_at = shipment.updated_at if shipment.state == 'canceled' &&
            shipment.cancelled_at.nil?
        shipment.save!
      rescue => ex
        puts "CopyUpdatedAtToFulfilledAtForShipments: #{ex}".red
      end
    end
  end

  def down
    # Do nothing.
  end
end
