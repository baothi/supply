class AddShopifyIdentifiersToOrdersAndInternalIdentifierToLineItems < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :internal_identifier, :string
    add_index :spree_line_items, :internal_identifier

    add_column :spree_orders, :supplier_shopify_identifier, :string
    add_column :spree_orders, :retailer_shopify_identifier, :string
  end
end
