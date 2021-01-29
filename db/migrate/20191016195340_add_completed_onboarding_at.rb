class AddCompletedOnboardingAt < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :completed_onboarding_at, :datetime
    add_column :spree_suppliers, :completed_onboarding_at, :datetime
  end
end
