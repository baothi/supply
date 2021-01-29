class AddOrderShopifyIdentifiers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :supplier_shopify_order_number, :integer
    add_column :spree_orders, :supplier_shopify_number, :integer
    add_column :spree_orders, :supplier_shopify_order_name, :string
    add_column :spree_orders, :shopify_sent_at, :datetime

    add_index :spree_orders, :supplier_shopify_order_number
    add_index :spree_orders, :supplier_shopify_number
    add_index :spree_orders, :supplier_shopify_order_name
    add_index :spree_orders, :shopify_sent_at

    add_index :spree_orders, :retailer_shopify_order_number
    add_index :spree_orders, :retailer_shopify_number
    add_index :spree_orders, :retailer_shopify_name
  end
end
