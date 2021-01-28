module Shopify
  module GraphAPI
    class Base
      def initialize(user)
        credentials = user.shopify_credential
        adapter = HTTPAdapter.new(
          url: credentials.store_url,
          access_token: credentials.access_token
        )
        @client = Client.new(adapter: adapter)
      end

      def graph_query(*args)
        @client.query(*args)
      end

      def self.encode_id(id, resource)
        "gid://shopify/#{resource}/#{id}".strip
      end

      def self.decode_id(shopify_graphql_id, resource)
        matches = shopify_graphql_id.match(/gid:\/\/shopify\/#{resource}\/(?<id>.*)/i)
        matches && matches[:id]
      end
    end
  end
end
