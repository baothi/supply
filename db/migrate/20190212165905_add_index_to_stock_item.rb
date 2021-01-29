class AddIndexToStockItem < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :spree_stock_items, :stock_location_id, algorithm: :concurrently
  end
end
