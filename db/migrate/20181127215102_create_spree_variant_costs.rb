class CreateSpreeVariantCosts < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_variant_costs do |t|
      # Supplier
      t.references :supplier, foreign_key: { to_table: 'spree_suppliers' }, null: false
      # SKU
      t.string :sku, null: false
      # MSRP
      t.string :msrp_currency, default: 'USD'
      t.decimal :msrp, null: false
      # Cost
      t.string :cost_currency, default: 'USD'
      t.decimal :cost, null: false
      # Minimum Advertised Price
      t.string :minimum_advertised_price_currency, default: 'USD'
      t.decimal :minimum_advertised_price
      t.timestamps
    end

    add_index :spree_variant_costs, [:supplier_id,
                                     :sku
    ],
              :name => 'index_on_spree_variant_costs_on_supplier_retailer_sku',
              :unique => true
  end
end
