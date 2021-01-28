module Spree
  class ShopifyCredential < ApplicationRecord
    # TODO: Confirm from Ismail what is intended in the following line

    # The owner of the credential
    belongs_to :teamable, polymorphic: true

    validates :store_url, :access_token, :teamable, presence: true

    attr_encrypted :access_token,
                   key: ENV['SHOPIFY_ACCESS_TOKEN_ENCRYPTION_KEY']&.first(32),
                   algorithm: 'aes-256-gcm',
                   mode: :per_attribute_iv,
                   insecure_mode: true

    # after_create :create_fulfillment_service, if: :retailer?

    def activate_shopify_session
      ShopifyAPI::Base.clear_session
      session = ShopifyAPI::Session.new(
        domain: store_url,
        token: access_token,
        api_version: ENV['SHOPIFY_API_VERSION']
      )
      ShopifyAPI::Base.activate_session(session)
    end

    # def create_fulfillment_service
    #   teamable.create_fulfillment_service
    # end

    def valid_connection?
      begin
        ShopifyAPI::Base.clear_session
        session = ShopifyAPI::Session.new(
          domain: self.store_url,
          token: self.access_token,
          api_version: ENV['SHOPIFY_API_VERSION']
        )
        ShopifyAPI::Base.activate_session(session)
        true if ShopifyAPI::Shop.current
      rescue => e
        if e.response.code == '401'
          puts e.response.body.red
          false
        end
      end
    end

    def retailer?
      teamable.class.to_s == 'Spree::Retailer'
    end

    def disable_connection!
      self.update(uninstalled_at: Time.now)
      return unless supplier?

      teamable.discontinue_products_and_variants!
    end

    private

    def supplier?
      teamable.class.to_s == 'Spree::Supplier'
    end
  end
end
