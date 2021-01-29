class AddOrderAutoPaymentToSpreeRetailers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :order_auto_payment, :boolean
  end
end
