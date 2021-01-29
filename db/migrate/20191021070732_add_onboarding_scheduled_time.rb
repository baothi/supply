class AddOnboardingScheduledTime < ActiveRecord::Migration[6.0]
  def change
    # Date that they scheduled onboarding
    add_column :spree_retailers, :scheduled_onboarding_at, :datetime
    # The time they selected for the onboarding
    add_column :spree_retailers, :onboarding_session_at, :datetime
  end
end
