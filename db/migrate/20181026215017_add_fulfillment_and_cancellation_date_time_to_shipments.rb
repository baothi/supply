class AddFulfillmentAndCancellationDateTimeToShipments < ActiveRecord::Migration[6.0]
  def change
    # Fulfillments
    add_column :spree_line_items, :fulfilled_at, :datetime
    add_column :spree_shipments, :fulfilled_at, :datetime
    # Cancellation
    add_column :spree_line_items, :cancelled_at, :datetime
    add_column :spree_shipments, :cancelled_at, :datetime
  end
end
