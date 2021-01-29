class ChangeJobJsonOptionColumnToJsonB < ActiveRecord::Migration[6.0]
  def change
    change_column :spree_long_running_jobs, :json_option_1, :jsonb, default: '{}', using: 'json_option_1::jsonb'
    add_index  :spree_long_running_jobs, :json_option_1, using: :gin
    change_column :spree_long_running_jobs, :json_option_2, :jsonb, default: '{}', using: 'json_option_2::jsonb'
    add_index  :spree_long_running_jobs, :json_option_2, using: :gin
    change_column :spree_long_running_jobs, :json_option_3, :jsonb, default: '{}', using: 'json_option_3::jsonb'
    add_index  :spree_long_running_jobs, :json_option_3, using: :gin
  end
end
