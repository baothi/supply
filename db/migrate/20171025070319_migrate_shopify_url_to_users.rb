class MigrateShopifyUrlToUsers < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::User.reset_column_information
      Spree::User.find_each do |user|
        shopify_url = user.teamable.try(:shopify_url)
        raise "User #{user.id} has an empty shopify_url. Cannot proceed" if
            shopify_url.nil?

        shopify_slug = shopify_url.split('.myshopify.com')[0]
        user.update!(
            shopify_url: shopify_url,
            shopify_slug: shopify_slug
        )
      end
    rescue => e
      puts "Error copying shopify_slug from teamables to user #{e.message}".red
    end
  end

  def down
    Spree::User.update_all(shopify_slug: nil, shopify_url: nil)
  end

end
