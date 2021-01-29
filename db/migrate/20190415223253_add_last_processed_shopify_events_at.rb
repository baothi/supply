class AddLastProcessedShopifyEventsAt < ActiveRecord::Migration[6.0]
  def change
    # Retailers
    add_column :spree_retailers, :last_processed_shopify_events_at, :datetime
    # Suppliers
    add_column :spree_suppliers, :last_processed_shopify_events_at, :datetime
  end
end
