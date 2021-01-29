class AddFilesToLongRunningJob < ActiveRecord::Migration[6.0]
  def change
    add_attachment :spree_long_running_jobs, :input_csv_file
    add_attachment :spree_long_running_jobs, :output_csv_file
  end
end
