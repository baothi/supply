class AddCourierAndShippingCodeToShippingMethods < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shipping_methods, :courier_name, :string
    add_column :spree_shipping_methods, :service_name, :string
    add_column :spree_shipping_methods, :service_code, :string
    add_column :spree_shipping_methods, :courier_id, :integer
    add_column :spree_shipping_methods, :active, :boolean
  end
end
