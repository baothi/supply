class CreateStripeInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_invoices do |t|
      t.string :internal_identifier
      t.references :stripe_customer
      t.string :invoice_identifier
      t.integer :amount_due
      t.integer :application_fee
      t.integer :attempt_count
      t.boolean :attempted
      t.string :charge_identifier
      t.boolean :closed
      t.string :currency
      t.string :customer_identifier
      t.timestamp :date
      t.string :description
      t.jsonb :discount
      t.boolean :forgiven
      t.timestamp :next_payment_attempt
      t.boolean :paid
      t.timestamp :period_end
      t.timestamp :period_start
      t.string :receipt_number
      t.integer :starting_balance
      t.string :statement_descriptor
      t.string :subscription_identifier
      t.integer :subtotal
      t.integer :total

      t.timestamps
    end
  end
end
