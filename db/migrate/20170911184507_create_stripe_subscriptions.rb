class CreateStripeSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_subscriptions do |t|
      t.string :internal_identifier
      t.string :subscription_identifier
      t.string :plan_identifier
      t.string :customer_identifier
      t.references :stripe_plan
      t.references :stripe_customer
      t.boolean :cancel_at_period_end
      t.timestamp :canceled_at
      t.timestamp :current_period_start
      t.timestamp :current_period_end
      t.integer :quantity
      t.timestamp :start
      t.timestamp :ended_at
      t.timestamp :trial_start
      t.timestamp :trial_end
      t.string :status

      t.timestamps
    end
  end
end
