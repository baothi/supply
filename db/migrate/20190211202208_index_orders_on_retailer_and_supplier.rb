class IndexOrdersOnRetailerAndSupplier < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :spree_orders, :retailer_id, algorithm: :concurrently
    add_index :spree_orders, :supplier_id, algorithm: :concurrently
  end
end
