class AddOriginalOrderDateToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :original_order_date, :datetime
  end
end
