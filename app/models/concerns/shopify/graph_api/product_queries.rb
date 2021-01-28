module Shopify
  module GraphAPI
    module ProductQueries
      extend ActiveSupport::Concern

      included do
        PRODUCT_FETCH_QUERY = Shopify::GraphAPI::QUERY.parse <<-'GRAPHQL'
          query($id: ID!){
            product(id: $id) {
              id
              title
              variants(first: 1) {
                edges {
                  node {
                    id
                  }
                }
              },
              totalVariants
            }
          }
        GRAPHQL

        PRODUCT_CREATE_QUERY = Shopify::GraphAPI::QUERY.parse <<-'GRAPHQL'
          mutation($input: ProductInput!, $variantsCount: Int) {
            productCreate(input: $input) {
              product {
                id
                title
                vendor
                variants(first: $variantsCount) {
                  edges {
                    node {
                      id
                      sku
                    }
                  }
                },
                totalVariants
              }
              userErrors {
                field
                message
              }
            }
          }
        GRAPHQL
      end
    end
  end
end
