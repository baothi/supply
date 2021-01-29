class CreateSpreeRetailConnections < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_retail_connections do |t|
      t.references  :retailer, null: false
      t.references  :supplier, null: false
      t.boolean  :auto_charge_orders, default: false
      t.string :ecommerce_platform # Will only support 'shopify' for now
      t.timestamps
    end

    add_index :spree_retail_connections, [:supplier_id, :retailer_id], unique: true
  end
end
