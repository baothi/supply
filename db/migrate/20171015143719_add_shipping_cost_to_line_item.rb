class AddShippingCostToLineItem < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :shipping_cost, :decimal, precision: 8, scale: 2, default: 0
  end
end
