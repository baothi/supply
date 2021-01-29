class AddAutoPaidAtToSpreeOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :auto_paid_at, :timestamp
    add_column :spree_orders, :auto_paid_retailer_notified_at, :timestamp
    add_index :spree_orders, :auto_paid_at
  end
end
