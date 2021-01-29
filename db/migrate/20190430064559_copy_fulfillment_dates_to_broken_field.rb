class CopyFulfillmentDatesToBrokenField < ActiveRecord::Migration[6.0]
  def up
    Spree::LineItem.update_all("invalid_fulfilled_at=fulfilled_at")
    Spree::Shipment.update_all("invalid_fulfilled_at=fulfilled_at")
  end

  def down
    # Do nothing
    Spree::LineItem.update_all(invalid_fulfilled_at: nil)
    Spree::Shipment.update_all(invalid_fulfilled_at: nil)
  end
end
