class CreateStripeCustomers < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_customers do |t|
      t.string :internal_identifier
      t.references :strippable, polymorphic: true
      t.string :customer_identifier
      t.integer :account_balance
      t.string :currency
      t.string :default_source
      t.boolean :delinquent
      t.string :description
      t.string :email
      t.jsonb :discount

      t.timestamps
    end
  end
end
