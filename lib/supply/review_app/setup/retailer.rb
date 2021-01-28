require_relative './base'

module Supply
  module ReviewApp
    module Setup
      class Retailer < Base
        def run
          create_retailer
        end

        def create_retailer
          shop = ENV['PR_SHOPIFY_STORE_SHOP_URL_RETAILER']
          retailer = create_teamable(Spree::Retailer, shop)

          retailer.shopify_url = retailer.domain = shop
          retailer.name = ENV['PR_SHOPIFY_STORE_NAME_RETAILER']
          retailer.shop_owner = "#{ENV['PR_SHOPIFY_STORE_NAME_RETAILER']} Admin"
          retailer.default_location_shopify_identifier =
            ENV['PR_SHOPIFY_STORE_RETAILER_LOCATION_ID']
          retailer.save

          create_shopify_credentials(retailer, shop, ENV['PR_SHOPIFY_STORE_ACCESS_TOKEN_RETAILER'])

          create_user(retailer)
        end
      end
    end
  end
end
