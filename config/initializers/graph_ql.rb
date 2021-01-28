module Shopify
  module GraphAPI
    path   = Rails.application.root.join('graphql', 'shopify', 'schema.json').to_s
    SCHEMA = GraphQL::Client.load_schema(path)
    QUERY  = GraphQL::Client.new(
      schema: SCHEMA
    )

    class Client
      def initialize(adapter:)
        @client = GraphQL::Client.new(
          schema: SCHEMA,
          execute: adapter
        )
      end

      delegate :query, to: :@client
    end

    class HTTPAdapter
      def initialize(url:, access_token:)
        url = "https://#{url}/admin/api/graphql.json"

        @http = GraphQL::Client::HTTP.new(url.to_s) do
          define_method(:headers) do |_|
            { 'X-Shopify-Access-Token' => access_token }
          end
        end
      end

      delegate :execute, to: :@http
    end
  end
end
