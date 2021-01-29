class AddSearchableAttributesToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :searchable_attributes, :text
  end
end
