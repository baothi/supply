class AddSettingsToSpreeLongRunningJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_long_running_jobs, :settings, :jsonb, default: {}
  end
end
