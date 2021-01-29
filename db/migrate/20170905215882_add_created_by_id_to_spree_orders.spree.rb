# This migration comes from spree (originally 20130725031716)
class AddCreatedByIdToSpreeOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :created_by_id, :integer
  end
end
