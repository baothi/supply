class CreateStripeCards < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_cards do |t|
      t.string :internal_identifier
      t.references :stripe_customer
      t.string :card_identifier
      t.string :address_city
      t.string :address_country
      t.string :address_line1
      t.string :address_line1_check
      t.string :address_line2
      t.string :address_state
      t.string :address_zip
      t.string :address_zip_check
      t.string :brand
      t.string :country
      t.string :customer_identifier
      t.string :cvc_check
      t.string :dynamic_last4
      t.integer :exp_month
      t.integer :exp_year
      t.string :fingerprint
      t.string :funding
      t.string :last4
      t.string :name

      t.timestamps
    end
  end
end
