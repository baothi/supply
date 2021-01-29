class AddDisablePaymentToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :disable_payments, :boolean
  end
end
