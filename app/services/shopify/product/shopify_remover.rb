module Shopify
  module Product
    class ShopifyRemover
      attr_accessor :retailer, :errors, :logs, :connected
      def initialize(opts = {})
        @retailer = Spree::Retailer.find_by(id: opts[:retailer_id])
        @errors = ''
        @logs = ''
      end

      def perform(internal_identifier)
        removed_from_shopify = true
        begin
          product_listing = Spree::ProductListing.find_by(
            internal_identifier: internal_identifier,
            retailer_id: @retailer.id
          )
          shopify_product =
            CommerceEngine::Shopify::Product.find(product_listing.shopify_identifier)
          ShopifyAPIRetry.retry(5) { shopify_product.destroy }
        rescue => e
          @errors << " #{e}\n"
          puts "#{@errors}".red
          removed_from_shopify = false
        end

        removed_locally = true
        # Regardless of the result above, we want to delete it from our side.
        begin
          unlist_local_product(product_listing)
        rescue => e
          @errors << " #{e}\n"
          puts "#{@errors}".red
          removed_locally = false
        end

        removed_locally && removed_from_shopify
      end

      def unlist_local_product(product_listing)
        begin
          variant_listings = product_listing.variant_listings
          variant_listings.each do |l|
            l.update(deleted_at: Time.now)
          end
          product_listing.update(deleted_at: Time.now)
          true
        rescue => e
          puts "#{@errors}".red
          @errors << " #{e}\n"
          false
        end
      end
    end
  end
end
