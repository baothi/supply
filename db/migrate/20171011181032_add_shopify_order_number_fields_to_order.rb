class AddShopifyOrderNumberFieldsToOrder < ActiveRecord::Migration[6.0]
  def change
     add_column :spree_orders, :retailer_shopify_order_number, :integer
     add_column :spree_orders, :retailer_shopify_name, :string
     add_column :spree_orders, :retailer_shopify_number, :string
  end
end
