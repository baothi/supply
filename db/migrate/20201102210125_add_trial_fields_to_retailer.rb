class AddTrialFieldsToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :remaining_trial_time, :integer, null: false, default: 1209600 # Seconds in 14 days
    add_column :spree_retailers, :trial_started_on, :datetime
  end
end
