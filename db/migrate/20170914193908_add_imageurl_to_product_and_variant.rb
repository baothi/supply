class AddImageurlToProductAndVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :image_urls, :text, array: true, default: []
    add_column :spree_variants, :image_urls, :text, array: true, default: []
  end
end
