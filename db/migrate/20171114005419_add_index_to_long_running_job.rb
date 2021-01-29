class AddIndexToLongRunningJob < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_long_running_jobs, :internal_identifier
  end
end
