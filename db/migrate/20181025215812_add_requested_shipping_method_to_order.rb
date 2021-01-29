class AddRequestedShippingMethodToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :requested_shipping_method_id, :integer
  end
end
