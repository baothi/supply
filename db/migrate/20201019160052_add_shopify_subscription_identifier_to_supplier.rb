class AddShopifySubscriptionIdentifierToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :current_shopify_subscription_identifier, :string
  end
end
