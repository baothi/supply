class CreateSpreeVariantListings < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_variant_listings do |t|
      t.integer :retailer_id, null: false
      t.integer :supplier_id, null: false
      t.integer :variant_id, null: false
      t.integer :retail_connection_id, null: false
      t.integer :storefront_id
      t.string :style_identifier
      t.string :identifier1
      t.string :identifier2
      t.string :identifier3 # For example, if retailer assigns a UPC
      t.string :internal_sku
      t.string :shopify_identifier
      t.string :internal_identifier
      t.timestamps
    end
    add_index :spree_variant_listings, [:retailer_id, :supplier_id, :variant_id],
              name: 'index_retailer_supplier_variant_id', unique: true
    add_index :spree_variant_listings, :retailer_id
    add_index :spree_variant_listings, :supplier_id
    add_index :spree_variant_listings, :variant_id
    add_index :spree_variant_listings, :retail_connection_id
    add_index :spree_variant_listings, :internal_identifier
  end
end
