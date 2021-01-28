# Used by Retailers and Suppliers
module Shopify::Monitor
  extend ActiveSupport::Concern

  included do
  end

  def connected_to_shopify?
    self.init
    begin
      true if ShopifyAPI::Shop.current
    rescue => e
      if e.response.code == '401'
        puts e.response.body.red
        false
      end
    end
  end

  def app_uninstalled?
    shopify_credential.uninstalled_at.present?
  end
end
