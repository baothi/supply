# The purpose of this service is for syncing single Shopify Order
module ShopifyCache
  class SingleOrderService
    # team: the supplier or retailer object

    attr_accessor :role, :shopify_url, :team,
                  :shopify_identifier,
                  :shopify_order, :shopify_object

    def initialize(team:, shopify_identifier: nil, shopify_object: nil)
      raise 'Team Type required' if team.blank?
      raise 'Shopify Object or Identifier required' if
          shopify_identifier.blank? && shopify_object.blank?

      @team = team
      @shopify_object = shopify_object
      @shopify_identifier = shopify_identifier
    end

    def retrieve_object
      @team.init # Initialize Shopify Session
      @shopify_url = @team.shopify_url

      @shopify_order = if @shopify_object.present?
                         @shopify_object
                       else
                         ShopifyAPIRetry.retry do
                           ShopifyAPI::Order.find(shopify_identifier)
                         end
                       end

      @role = @team.team_type
    end

    def perform
      begin
        retrieve_object

        to_insert = @shopify_order.attributes
        to_insert[:shopify_url] = shopify_url
        to_insert[:role] = role
        to_insert[:num_line_items] = to_insert[:line_items].count
        ShopifyCache::Order.new(ActiveSupport::JSON.decode(to_insert.to_json)).upsert
      rescue => ex
        ErrorService.new(exception: ex).perform
      end
    end
  end
end
