class AddDropshippingTotalToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :total_shipment_cost, :decimal, precision: 8, scale: 2, default: 0
  end
end
