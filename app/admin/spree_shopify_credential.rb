ActiveAdmin.register Spree::ShopifyCredential do
  remove_filter :encrypted_access_token, :encrypted_access_token_iv, :created_at, :updated_at
  menu parent: 'Team', label: 'Shopify Credentials'

  index download_links: false, pagination_total: false  do
    column :id
    column :store_url
    column :teamable
    column :active do |c|
      c.uninstalled_at.nil?
    end
    column :uninstalled_at
  end
end
