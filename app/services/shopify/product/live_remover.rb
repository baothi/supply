module Shopify
  module Product
    class LiveRemover < Base
      def perform(product_listing_id)
        begin
          product_listing = Spree::ProductListing.find_by(internal_identifier: product_listing_id)
          variant_listings = product_listing.variant_listings
          variant_listings.each do |l|
            l.update(deleted_at: Time.now)
          end
          product_listing.update(deleted_at: Time.now)
        rescue => e
          @errors << " #{e}\n"
          false
        end
      end
    end
  end
end
