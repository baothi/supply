class AddCancelledAtToInventoryUnit < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_inventory_units, :cancelled_at, :datetime
  end
end
