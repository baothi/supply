class CreateSpreeSupplierReferrals < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_supplier_referrals do |t|
      t.string :name
      t.string :string
      t.string :url
      t.string :email
      t.string :image_url
      t.boolean :has_relationship
      t.references :spree_retailer, foreign_key: true

      t.timestamps
    end
  end
end
