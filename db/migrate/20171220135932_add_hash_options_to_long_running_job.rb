class AddHashOptionsToLongRunningJob < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_long_running_jobs, :hash_option_1, :string
    add_column :spree_long_running_jobs, :hash_option_2, :string
    add_column :spree_long_running_jobs, :hash_option_3, :string
    add_column :spree_long_running_jobs, :json_option_1, :string
    add_column :spree_long_running_jobs, :json_option_2, :string
    add_column :spree_long_running_jobs, :json_option_3, :string
    add_column :spree_long_running_jobs, :array_option_1, :string
    add_column :spree_long_running_jobs, :array_option_2, :string
    add_column :spree_long_running_jobs, :array_option_3, :string
  end
end
