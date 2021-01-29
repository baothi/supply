class AddShopifyUrlToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :spree_users, :shopify_slug, :string, index: true
    add_column :spree_users, :shopify_url, :string, index: true
    add_index :spree_users, [:email, :shopify_slug], unique: true
    add_index :spree_users, [:email, :shopify_url], unique: true
    remove_index :spree_users, :email
  end

  def down
    remove_index :spree_users, [:email, :shopify_slug]
    remove_index :spree_users, [:email, :shopify_url]
    remove_column :spree_users, :shopify_slug
    remove_column :spree_users, :shopify_url
    add_index :spree_users, :email, unique: true
  end
end
