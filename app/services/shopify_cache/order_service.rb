# Keep in mind that unless we are using a private app for the orders, that we will only be able to
# go back up to 60 days worth of orders.
# Private apps do not have this limitation.
module ShopifyCache
  class OrderService
    # team: the supplier or retailer object
    # params: custom shopify finder params e.g. {"updated_at_min": DateTime.now - 1.day}.to_json

    attr_accessor :custom_params, :role, :shopify_url, :team

    def initialize(team:, params: '{}')
      raise 'Team Type required' if team.blank?

      @team = team

      @role = @team.team_type
      @shopify_url = team.shopify_url
      @custom_params = JSON.parse(params)
    end

    def perform
      begin
        @team.init # Initialize Shopify Session

        # Iterate through the pages of returned orders

        # Find all the products
        shopify_orders = ShopifyAPIRetry.retry do
          ShopifyAPI::Order.all(
            params: { status: 'any', limit: PER_PAGE.to_i }.merge(custom_params)
          )
        end
        process_orders(shopify_orders)

        while shopify_orders.next_page?
          shopify_orders = shopify_orders.fetch_next_page
          process_orders(shopify_orders)
        end

        @team.last_synced_shopify_orders_at = DateTime.now
        @team.save!
      rescue => ex
        ErrorService.new(exception: ex).perform
      end
    end

    private

    PER_PAGE = 250.0

    def process_orders(shopify_orders)
      # Insert into MongoDB
      shopify_orders.map! do |order|
        order = order.attributes
        order[:shopify_url] = shopify_url
        order[:role] = role
        order[:num_line_items] = order[:line_items].count
        order
      end

      # Upsert the Orders
      shopify_orders.each do |order|
        ShopifyCache::Order.new(ActiveSupport::JSON.decode(order.to_json)).upsert
      end
    end
  end
end
