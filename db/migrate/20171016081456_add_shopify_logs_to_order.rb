class AddShopifyLogsToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :shopify_logs, :text
  end
end
