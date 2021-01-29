class CreateSpreeRetailerInventories < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_retailer_inventories do |t|
      t.references :retailer, foreign_key: { to_table: 'spree_retailers' }, index: { unique: true }
      t.jsonb :inventory, null: false, default: '{}'
      # We have an explicit column (instead of relying on updated_at) in the event
      # we add future fields that are updateable
      t.datetime :last_generated_at
      t.timestamps
    end
  end
end
