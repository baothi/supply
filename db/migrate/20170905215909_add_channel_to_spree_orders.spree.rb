# This migration comes from spree (originally 20131113035136)
class AddChannelToSpreeOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :channel, :string, default: "spree"
  end
end
