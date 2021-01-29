class AddStripeSubscriptionInfo < ActiveRecord::Migration[6.0]
  def change
    # Spree Retailers
    add_column :spree_retailers, :current_stripe_customer_identifier, :string
    add_column :spree_retailers, :current_stripe_subscription_identifier, :string
    add_column :spree_retailers, :current_stripe_subscription_started_at, :string
    add_column :spree_retailers, :current_stripe_plan_identifier, :string
    # Spree Suppliers
    add_column :spree_suppliers, :current_stripe_customer_identifier, :string
    add_column :spree_suppliers, :current_stripe_subscription_identifier, :string
    add_column :spree_suppliers, :current_stripe_subscription_started_at, :string
    add_column :spree_suppliers, :current_stripe_plan_identifier, :string
  end
end
