module Shopify
  module GraphAPI
    class Product < Base
      include ProductQueries

      def create(product_input_hash, variants_count = 1)
        graph_query(PRODUCT_CREATE_QUERY, variables: {
            input: product_input_hash,
            variantsCount: variants_count
        })
      end

      def find(product_id)
        graph_query(PRODUCT_FETCH_QUERY, variables: { id: encode_id(product_id, :Product) })
      end
    end
  end
end
