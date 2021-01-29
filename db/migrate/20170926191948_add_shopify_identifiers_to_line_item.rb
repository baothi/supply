class AddShopifyIdentifiersToLineItem < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :supplier_shopify_identifier, :string
    add_column :spree_line_items, :retailer_shopify_identifier, :string
  end
end
