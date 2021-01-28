module Shopify
  module Variant
    class BulkSkuUpdater
      attr_accessor :retailer, :ro

      def initialize(opts = {})
        validate opts
      end

      def validate(opts)
        raise 'Retailer id is required' unless opts[:retailer_id].present?

        @retailer = Spree::Retailer.find(opts[:retailer_id])
        raise 'Unable to find retailer by id provided' if retailer.nil?
      end

      def perform
        @ro = ResponseObject.success_response_object('N/A')
        begin
          raw_mutation = <<-GRAPHQL
            mutation {
              #{generate_variants_mutations.join}
            }
          GRAPHQL

          client = Shopify::GraphAPI::Base.new(retailer)
          self.class.const_set(:VARIANTS_MUTATION, Shopify::GraphAPI::QUERY.parse(raw_mutation))

          result = client.graph_query(VARIANTS_MUTATION)

          return unless result.original_hash && result.original_hash['data'].present?

          log_result result.original_hash['data']
        rescue => e
          puts "#{e}".red
          ro.message = " #{e}\n"
          ro.fail!
        end
        ro
      end

      private

      def mxed_product?(shopify_product)
        shopify_variant = shopify_product.variants.first
        found_product = ShopifyCache::Product.where(
          role: 'supplier',
          shopify_url: 'mxed.shopify.com',
          'variants.sku': shopify_variant.sku
        ).first
        found_product.present?
      end

      def bravado_product?(shopify_product)
        shopify_variant = shopify_product.variants.first
        found_product = ShopifyCache::Product.where(
          role: 'supplier',
          shopify_url: 'bravadousa.shopify.com',
          'variants.sku': shopify_variant.sku
        ).first
        found_product.present?
      end

      def generate_variants_mutations
        variant_mutations = []
        retailer_products = ShopifyCache::Product.where(role: 'retailer', shopify_url: retailer.shopify_url)
        retailer_products.each_with_index do |shopify_product, i|
          # If the product is a MXED product? update its SKUs
        end

        retailer.variant_listings.each_with_index do |listing, i|
          variant_graph_id = Shopify::GraphAPI::Base.encode_id(
            listing.shopify_identifier, :ProductVariant
          )

          variant_properties = listing.variant.shopify_params(retailer)

          # inventoryQuantities is a create only field as per shopify graphQL
          # productVariantUpdate documentation. Quantities are to be updated through
          # separate mutation.
          # fulfillmentServiceId field accepts a valid graph id of a fulfillmentService
          # created at shopify. However, if we don't submit the fulfillmentServiceId
          # it sets the default value to be "manual"

          mutation = <<-GRAPHQL
              ProductVariant#{i + 1}: productVariantUpdate(input: {
                id: "#{variant_graph_id}",
                sku: "#{variant_properties[:sku]}",
              }){
                productVariant {
                  id
                  title
                  sku
                  price
                  weight
                  inventoryQuantity
                  fulfillmentService { serviceName }
                }
                userErrors {
                  field
                  message
                }
              }
          GRAPHQL

          variant_mutations << mutation
        end

        variant_mutations
      end

      def log_result(result)
        puts 'Updated Variants: '.blue

        result.each do |k, v|
          # next if v['productVariant'].nil?

          if v['userErrors'].any?
            puts "Error updating #{k}:".red
            errors = v['userErrors'].map { |error| error['message'] }.join('\n')
            puts errors.red
            next
          end

          puts "updated #{k}...".green
          puts "ID: #{v['productVariant']['id']}"
          puts "Title: #{v['productVariant']['title']}"
          puts "SKU: #{v['productVariant']['sku']}"
          puts "Price: #{v['productVariant']['price']}"
          puts "Quantity: #{v['productVariant']['inventoryQuantity']}"
        end
      end
    end
  end
end
