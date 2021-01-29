class AddIndexToProductShopifyIdentifier < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_products, :shopify_identifier
    add_index :spree_variants, :shopify_identifier
  end
end
