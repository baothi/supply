require 'spree'

namespace :shopify_credentials do
  desc 'check for invalid credentials'
  task check_valid_credentials: :environment do
    Spree::ShopifyCredential.find_each do |shopify_credential|
      begin
        next if shopify_credential.valid_connection?
        next if shopify_credential.teamable.app_uninstalled?

        shopify_credential.disable_connection!
      rescue => e
        puts e.to_s
        next
      end
    end
  end
end
