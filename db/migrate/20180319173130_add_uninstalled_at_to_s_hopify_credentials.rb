class AddUninstalledAtToSHopifyCredentials < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shopify_credentials, :uninstalled_at, :datetime
  end
end
