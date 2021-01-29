class AddVendorStyleIdentifierToSpreeProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :vendor_style_identifier, :string
    add_index :spree_products, :vendor_style_identifier
  end
end
