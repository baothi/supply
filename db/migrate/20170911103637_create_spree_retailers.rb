class CreateSpreeRetailers < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_retailers do |t|
      t.string  :name, null: false
      t.string  :slug, null: false
      t.string  :email, null: false
      t.string  :ecommerce_platform
      t.string  :internal_identifier
      t.string  :facebook_url
      t.string  :instagram_url
      t.string  :website
      t.string  :phone_number
      t.string  :primary_country
      # Taxation
      t.string :tax_identifier_type # ein or ssn
      t.string :encrypted_tax_identifier
      t.string :encrypted_tax_identifier_iv
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :spree_retailers, :email
    add_index :spree_retailers, :internal_identifier, unique: true
    add_index :spree_retailers, :slug, unique: true
  end
end
