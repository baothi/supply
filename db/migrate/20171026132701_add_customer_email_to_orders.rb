class AddCustomerEmailToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :customer_email, :string, index: true
  end
end
