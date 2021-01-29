class AddSupplierStripeSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :scheduled_onboarding_at, :datetime
    # The time they selected for the onboarding
    add_column :spree_suppliers, :onboarding_session_at, :datetime
  end
end
