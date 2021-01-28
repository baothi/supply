module Shopify
  class Base
    attr_reader :connection_error, :connected, :errors, :logs, :team
    require 'open-uri'
    def initialize(opts = {})
      validate opts
      @supplier = Spree::Supplier.find_by(id: opts[:supplier_id]) if opts[:supplier_id]
      @retailer = Spree::Retailer.find_by(id: opts[:retailer_id])

      id = opts[:teamable_id]
      teamable_klass = opts[:teamable_type].constantize
      @team = teamable_klass.find_by(id:  id)
      @teamable_type = opts[:teamable_type]

      @shopify_credential = @team.shopify_credential

      raise 'No shopify credential was found for this connection' if @shopify_credential.blank?

      begin
        set_base_site
        ShopifyAPI::Shop.current
        @errors = ''
        @logs = ''
        @connected = true
      rescue => e
        @connected = false
        @connection_error = e.to_s
        return
      end
    end

    def validate(opts)
      raise 'Teamable type not present'  if opts[:teamable_type].blank?

      if opts[:teamable_type] == 'Spree::Retailer' && opts[:retailer_id].blank?
        raise 'Retailer id not present'
      end
      # if opts[:teamable_type] == 'Spree::Supplier' && opts[:supplier_id].blank?
      #   raise 'Retailer id not present'
      # end
      raise 'Team not set'  if opts[:teamable_id].blank?
    end

    def set_base_site
      ShopifyAPI::Base.clear_session
      return unless @shopify_credential.access_token.present?

      session = ShopifyAPI::Session.new(
        domain: @shopify_credential.store_url,
        token: @shopify_credential.access_token,
        api_version: ENV['SHOPIFY_API_VERSION'] 
      )
      ShopifyAPI::Base.activate_session(session)
    end

    def get_total_records(klass, from, to)
      client = CommerceEngine::Shopify::Generic.corresponding_shopify_commerce_engine(klass)
      response = if from.present? && to.present?
                   client.find(
                     :all, params: { created_at_min: from, created_at_max: to }
                   ).count
                 else
                   client.count
                 end
      response
    end

    def find_in_batches(klass, from, to)
      client = CommerceEngine::Shopify::Generic.corresponding_shopify_commerce_engine(klass)
      response = if from.present? && to.present?
                   client.find(
                     :all,
                     params: { limit: 250, created_at_min: from, created_at_max: to }
                   )
                 else
                   client.find(:all, params: { limit: 250 })
                 end
      response
    end
  end
end
