class CreateSpreeRetailerCredits < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_retailer_credits do |t|
      t.references :retailer, foreign_key: { to_table: 'spree_retailers' }
      t.decimal :by_bioworld
      t.decimal :by_hingeto

      t.timestamps
    end
  end
end
