module ShopifyCache
  class ProductService
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

        # Find all the products
        shopify_products = ShopifyAPIRetry.retry do
          ShopifyAPI::Product.all(
            params: {
                limit: PER_PAGE.to_i
            }.merge(custom_params)
          )
        end
        process_products(shopify_products)

        while shopify_products.next_page?
          shopify_products = shopify_products.fetch_next_page
          process_products(shopify_products)
        end

        @team.last_synced_shopify_products_at = DateTime.now
        @team.save!
      rescue => ex
        ErrorService.new(exception: ex).perform
      end
    end

    private

    PER_PAGE = 250.0

    def process_products(shopify_products)
      # update search attributes of any local products
      shopify_products.each do |sp|
        local_product = Spree::Product.find_by(shopify_identifier: sp.id.to_s)
        local_product.update_search_attributes! unless local_product.nil?
      end

      # Insert into MongoDB
      shopify_products.map! do |product|
        product = product.attributes
        product[:shopify_url] = shopify_url
        product[:role] = role
        product
      end

      # Upsert the Product
      shopify_products.as_json.each do |product|
        ShopifyCache::Product.new(product).upsert
      end
    end
  end
end
