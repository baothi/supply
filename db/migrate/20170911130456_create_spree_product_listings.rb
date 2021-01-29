class CreateSpreeProductListings < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_product_listings do |t|
      t.integer :retailer_id, null: false
      t.integer :supplier_id, null: false
      t.integer :product_id, null: false
      t.integer :retail_connection_id, null: false
      t.string :aasm_state # same as above. Re-added to be consistent with variant_listing
      t.string :style_identifier
      t.string :shopify_identifier
      t.string :internal_identifier
      t.timestamps
    end
    add_index :spree_product_listings, [:retailer_id, :supplier_id, :product_id],
              name: 'index_product_listing_retailer_supplier_product_id', unique: true
    add_index :spree_product_listings, :retailer_id
    add_index :spree_product_listings, :retail_connection_id
    add_index :spree_product_listings, :supplier_id
    add_index :spree_product_listings, :product_id
    add_index :spree_product_listings, :style_identifier
    add_index :spree_product_listings, :internal_identifier
  end
end
