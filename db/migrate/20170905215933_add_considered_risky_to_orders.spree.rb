# This migration comes from spree (originally 20140219060952)
class AddConsideredRiskyToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :considered_risky, :boolean, default: false
  end
end
