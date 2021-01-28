module Shopify
  module Variant
    class BulkUpdater
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

      def generate_variants_mutations
        variant_mutations = []
        retailer.variant_listings.each_with_index do |listing, i|
          next if listing.shopify_identifier.blank?

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
                options: ["#{variant_properties[:options].first}", "#{variant_properties[:options].last}"],
                sku: "#{variant_properties[:sku]}",
                inventoryManagement: #{variant_properties[:inventoryManagement]},
                price: "#{variant_properties[:price]}",
                weight: #{variant_properties[:weight]},
                weightUnit: #{variant_properties[:weightUnit]}
              }){
                productVariant {
                  id
                  title
                  sku
                  price
                  weight
                  weightUnit
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
          puts "Weight: #{v['productVariant']['weight']} #{v['productVariant']['weightUnit']}"
          puts "Quantity: #{v['productVariant']['inventoryQuantity']}"
          puts "Fulfillment Service: #{v['productVariant']['fulfillmentService']['serviceName']}"
        end
      end
    end
  end
end
