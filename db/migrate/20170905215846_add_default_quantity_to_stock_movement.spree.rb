# This migration comes from spree (originally 20130307161754)
class AddDefaultQuantityToStockMovement < ActiveRecord::Migration[6.0]
  def change
    change_column :spree_stock_movements, :quantity, :integer, default: 0
  end
end
