class AddShopifySubscriptionIdentifierToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :current_shopify_subscription_identifier, :string
  end
end
