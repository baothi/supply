class AddProductTypeToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :shopify_product_type, :string
  end
end
