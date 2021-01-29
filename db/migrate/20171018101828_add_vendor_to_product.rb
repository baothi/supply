class AddVendorToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :shopify_vendor, :string
    add_column :spree_products, :license_name, :string
  end
end
