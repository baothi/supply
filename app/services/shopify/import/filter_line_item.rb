module Shopify
  module Import
    class FilterLineItem
      def initialize(opts = {})
        @shopify_order = opts[:order]
        @retailer = opts[:retailer]
        @shopify_filtered_line_items = []
      end

      def perform
        shopify_line_items = @shopify_order.line_items
        shopify_line_items.each do |shopify_line_item|
          if variant_exists?(shopify_line_item) && !imported?(shopify_line_item.id)
            @shopify_filtered_line_items << shopify_line_item
          end
        end
        @shopify_filtered_line_items
      end

      def variant_exists?(shopify_line_item)
        variant_listing = Spree::VariantListing.find_by(
          shopify_identifier: shopify_line_item.variant_id,
          retailer_id: @retailer.id
        )

        product_id = shopify_line_item.product_id
        sku = shopify_line_item.sku

        variant_listing.present? || hingeto_product?(product_id) || located_with_sku?(sku)
      end

      def imported?(shopify_identifier)
        Spree::LineItem.find_by(
          retailer_id: @retailer.id,
          retailer_shopify_identifier: shopify_identifier
        )
      end

      def hingeto_product?(product_id)
        retailer = @retailer
        begin
          retailer.initialize_shopify_session!
          product = CommerceEngine::Shopify::Product.find(product_id)
          retailer.destroy_shopify_session!
          product.tags.include?('hingeto') || product.tags.include?('supply') ||
            product.tags.include?('mxed')
        rescue
          false
        end
      end

      def located_with_sku?(variant_sku)
        Spree::Variant.find_by(platform_supplier_sku: variant_sku&.upcase).present?
      end
    end
  end
end
