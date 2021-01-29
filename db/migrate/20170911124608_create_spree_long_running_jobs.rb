class CreateSpreeLongRunningJobs < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_long_running_jobs do |t|
      t.references :retailer
      t.references :supplier
      t.references :user
      t.string :initiated_by, null: false  # platform or user
      t.string :action_type, null: false  # import vs export?
      # Job Types - shopify_import, listings_exports, listings_import, process_attributes
      t.string :job_type, null: false
      # Job Status - scheduled, in_progress, failed, error, complete
      t.string :status, null: false
      # Configurable options
      t.string :option_1
      t.string :option_2
      t.string :option_3
      t.string :option_4
      t.string :option_5
      t.string :option_6
      t.string :option_7
      t.string :option_8
      t.string :option_9
      t.string :option_10
      # Shopify Related
      t.string :shopify_publish_status
      t.datetime :time_started
      t.datetime :time_completed
      # The overall amount of time the job took - in milliseconds
      t.decimal :completion_time, :precision => 8, :scale => 2
      # Progress Related
      t.integer :num_of_records_processed
      t.integer :num_of_records_not_processed
      t.integer :total_num_of_records
      t.integer :num_of_errors
      t.boolean :force_image_download
      # From 0.00 - 100.00
      t.decimal :progress, :precision => 8, :scale => 2
      # For Logging
      t.text :log
      t.text :error_log
      # Notification
      t.string :email_recipients
      # Auditing
      t.string :input_data
      # Internal Identifier
      t.string :internal_identifier
      t.timestamps
    end
    # We use teamable to tell us who ran the job. We use reatiler/supplier/user
    # as a means to store an object to work with
    add_reference :spree_long_running_jobs, :teamable, polymorphic: true, index: true
  end
end
