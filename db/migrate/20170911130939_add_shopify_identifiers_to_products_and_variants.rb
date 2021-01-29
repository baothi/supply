class AddShopifyIdentifiersToProductsAndVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :shopify_identifier, :string
    add_column :spree_variants, :shopify_identifier, :string
  end
end
