class AddSlugToProductListings < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_product_listings, :shopify_title, :string
    add_column :spree_product_listings, :shopify_handle, :string
  end
end
