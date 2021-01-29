class AddDefaultRetailerShipmentMethod < ActiveRecord::Migration[6.0]
  def change
    # The default shipping method to set on orders if one isn't specified
    add_column :spree_retailers, :default_us_shipping_method_id, :integer
    add_column :spree_retailers, :default_canada_shipping_method_id, :integer
    add_column :spree_retailers, :default_rest_of_world_shipping_method_id, :integer
  end
end
