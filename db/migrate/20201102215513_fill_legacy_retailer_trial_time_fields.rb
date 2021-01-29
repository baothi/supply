class FillLegacyRetailerTrialTimeFields < ActiveRecord::Migration[6.0]
  def change
    Spree::Retailer.update_all(remaining_trial_time: 0, trial_started_on: Time.now)
  end
end
