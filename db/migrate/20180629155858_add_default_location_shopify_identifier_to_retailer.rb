class AddDefaultLocationShopifyIdentifierToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :default_location_shopify_identifier, :string
  end
end
