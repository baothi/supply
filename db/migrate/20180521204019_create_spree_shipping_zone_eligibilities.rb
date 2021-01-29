class CreateSpreeShippingZoneEligibilities < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_shipping_zone_eligibilities do |t|
      t.references :supplier, foreign_key: { to_table: 'spree_suppliers' }
      t.references :zone, foreign_key: { to_table: 'spree_zones' }
      t.timestamps
    end
    add_index :spree_shipping_zone_eligibilities,
              [:supplier_id, :zone_id],
              name: 'index_spree_shipping_zone_eligibilities_on_supplier_zone_id'
  end
end
