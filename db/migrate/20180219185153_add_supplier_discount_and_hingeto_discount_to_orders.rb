class AddSupplierDiscountAndHingetoDiscountToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :supplier_discount, :decimal, default: 0.0
    add_column :spree_orders, :hingeto_discount, :decimal, default: 0.0
    add_column :spree_orders, :applied_shipping_discount, :decimal, default: 0.0
  end
end
