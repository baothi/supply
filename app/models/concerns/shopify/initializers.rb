# Used by VariantListing.
module Shopify::Initializers
  extend ActiveSupport::Concern

  included do
  end

  def initialize_shopify_session!
    ShopifyAPIRetry.retry(3) { begin_initialization }
  end

  def begin_initialization
    ShopifyAPI::Base.clear_session
    @shopify_credential = self.shopify_credential
    raise 'Shopify Credential is required' if @shopify_credential.nil?
    return unless @shopify_credential.access_token.present?

    session = ShopifyAPI::Session.new(
      domain: @shopify_credential.store_url,
      token: @shopify_credential.access_token,
      api_version: ENV['SHOPIFY_API_VERSION']
    )
    ShopifyAPI::Base.activate_session(session)
  end

  # Alias
  alias_method :init, :initialize_shopify_session!

  def destroy_shopify_session!
    ShopifyAPIRetry.retry(3) { ShopifyAPI::Base.clear_session }
  end
end
