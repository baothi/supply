class AddLastSyncedDatesToRetailersAndSuppliers < ActiveRecord::Migration[6.0]
  def change
    # Retailers
    add_column :spree_retailers, :last_synced_shopify_events_at, :datetime
    add_column :spree_retailers, :last_synced_shopify_products_at, :datetime
    add_column :spree_retailers, :last_synced_shopify_orders_at, :datetime
    # Suppliers
    add_column :spree_suppliers, :last_synced_shopify_events_at, :datetime
    add_column :spree_suppliers, :last_synced_shopify_products_at, :datetime
    add_column :spree_suppliers, :last_synced_shopify_orders_at, :datetime
  end
end
