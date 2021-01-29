class CreateSpreeShopifyCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_shopify_credentials do |t|
      t.integer :retail_connection_id, null: false
      t.string :store_url
      t.string :encrypted_access_token
      t.string :encrypted_access_token_iv

      t.timestamps
    end
    add_index :spree_shopify_credentials, :retail_connection_id, unique: true
  end
end
