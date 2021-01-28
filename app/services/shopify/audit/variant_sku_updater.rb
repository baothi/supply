module Shopify
  module Audit
    class VariantSkuUpdater
      # require 'celluloid/current'

      # include Celluloid

      attr_accessor :retailer, :errors, :logs

      def initialize(opts = {})
        @retailer = opts[:retailer]
      end

      def validate
        raise 'Retailer must be set' if @retailer.nil?
      end

      def perform_async(opts)
        @retailer = opts[:retailer]
        perform
      end

      def connect_to_shopify
        raise 'Could not connect to shopify' unless
            @retailer.initialize_shopify_session!
      end

      def disconnect_from_shopify
        @retailer.destroy_shopify_session!
      end

      def perform
        validate

        begin
          connect_to_shopify
          variant_listings = retailer.variant_listings
          variant_listings_ids = variant_listings.pluck(:shopify_identifier)

          variant_listings_ids.each_slice(250) do |ids|
            shopify_variants = ShopifyAPI::Variant.find(
              :all,
              params: { ids: ids.join(','), limit: 250 }
            )
            next if shopify_variants.empty?

            shopify_variants.each do |shopify_variant|
              variant = variant_listings.find_by(shopify_identifier: shopify_variant.id)&.variant
              next unless variant.present?

              shopify_variant.sku = variant.platform_supplier_sku
              ShopifyAPIRetry.retry { shopify_variant.save }
              puts shopify_variant.sku
              puts shopify_variant.id
            end
          end
          disconnect_from_shopify
        rescue => ex
          puts "#{ex} for retailer: #{@retailer.name} - #{@retailer.id}".red
        end
      end
    end
  end
end
