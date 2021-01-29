class AddShippingCostToShipments < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shipments, :per_item_cost, :decimal, precision: 8, scale: 2, default: 0
  end
end
