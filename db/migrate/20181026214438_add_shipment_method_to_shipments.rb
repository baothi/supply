class AddShipmentMethodToShipments < ActiveRecord::Migration[6.0]
  def change
    # For us to help figure out what suppliers are using to Ship?
    add_column :spree_shipments, :courier_id, :integer
    add_column :spree_shipments, :shipping_method_id, :integer
  end
end
