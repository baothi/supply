module Spree::RetailersAndSuppliers::ShopifyInstallable
  extend ActiveSupport::Concern

  included do
    scope :installed, -> {
      joins(:shopify_credential).where('spree_shopify_credentials.uninstalled_at is null')
    }

    scope :uninstalled, -> {
      joins(:shopify_credential).where('spree_shopify_credentials.uninstalled_at is not null')
    }
  end
end
