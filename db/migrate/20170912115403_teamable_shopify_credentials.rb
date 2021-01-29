class TeamableShopifyCredentials < ActiveRecord::Migration[6.0]
  def up
    remove_column :spree_shopify_credentials, :retail_connection_id
    add_column :spree_shopify_credentials, :teamable_type, :string
    add_column :spree_shopify_credentials, :teamable_id, :integer
    add_index :spree_shopify_credentials, [:teamable_type, :teamable_id],
              :name => 'index_on_teamable_for_shopify_credentials'
  end

  def down
    add_column :spree_shopify_credentials, :retail_connection_id, :integer
    remove_column :spree_shopify_credentials, :teamable_id
    remove_column :spree_shopify_credentials, :teamable_type
  end
end
