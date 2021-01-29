class AddPurchaseOrderNumberToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :purchase_order_number, :string
  end
end
