class AddShopifyUrlToSupplierAndRetailer < ActiveRecord::Migration[6.0]
  def change
    # Since this is mostly a shopify app, helpful to have this on the
    # supplier/retailer as well.
    add_column :spree_suppliers, :shopify_url, :string
    add_column :spree_retailers, :shopify_url, :string
    # Indices
    add_index :spree_suppliers, :shopify_url
    add_index :spree_retailers, :shopify_url
  end
end
