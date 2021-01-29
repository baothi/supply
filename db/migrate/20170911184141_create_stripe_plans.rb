class CreateStripePlans < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_plans do |t|
      t.string :internal_identifier
      t.string :plan_identifier
      t.string :name
      t.integer :amount
      t.string :currency
      t.string :interval
      t.integer :interval_count
      t.string :description
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
