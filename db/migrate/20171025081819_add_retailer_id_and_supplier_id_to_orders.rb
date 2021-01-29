class AddRetailerIdAndSupplierIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :retailer_id, :integer, index: true
    add_column :spree_orders, :supplier_id, :integer, index: true
  end
end
