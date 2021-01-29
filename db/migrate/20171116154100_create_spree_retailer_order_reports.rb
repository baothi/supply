class CreateSpreeRetailerOrderReports < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_retailer_order_reports do |t|
      t.references :retailer
      t.references :supplier
      t.references :retail_connection
      t.string :source
      t.datetime :report_generated_at
      t.integer :num_of_orders_last_30_days
      t.integer :num_of_orders_last_60_days
      t.integer :num_of_orders_last_90_days
      t.timestamps
    end
  end
end
