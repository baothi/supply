class AddArchivedAtToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :archived_at, :datetime
  end
end
