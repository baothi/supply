# Used by VariantListing.
module CommerceEngine::Shopify::Base
  extend ActiveSupport::Concern
  class_methods do
    def corresponding_shopify_commerce_engine(shopify_klass)
      raise if shopify_klass.nil?

      klass_name = shopify_klass.split('::')[1]
      klass = "CommerceEngine::Shopify::#{klass_name}".constantize
      klass
    end

    def kalling_klass
      "#{name.split('::')[2]}"
    end

    def shopify_klass
      "ShopifyAPI::#{kalling_klass}".constantize
    end

    def create(params)
      val = ShopifyAPIRetry.retry do
        shopify_klass.new(params)
      end
      val
    end

    def find(conditions, params = {})
      val = ShopifyAPIRetry.retry do
        if params.blank? || params.empty?
          shopify_klass.find(conditions)
        else
          shopify_klass.find(conditions, params)
        end
      end
      val
    end

    def count(params = {})
      val = ShopifyAPIRetry.retry do
        shopify_klass.count(params)
      end
      val
    end

    def current
      val = ShopifyAPIRetry.retry do
        shopify_klass.current
      end
      val
    end

    def destroy(id)
      val = ShopifyAPIRetry.retry do
        shopify_klass.delete(id)
      end
      val
    end
  end
end
