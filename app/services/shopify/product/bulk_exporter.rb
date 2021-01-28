# frozen_string_literal: true

module Shopify
  module Product
    class BulkExporter
      attr_reader :local_products, :retailer

      def initialize(local_products:, retailer:)
        @local_products = local_products
        @retailer = retailer
      end

      def perform
        return if local_products.empty?

        if missing_products_ids.empty?
          'All products exist on your shopify store!'
        else
          add_missing_products_to_shopify
          'All new products have been added to your shopify store'
        end
      end

      private

      def missing_products_ids
        local_products.ids - shopify_products_ids
      end

      def add_missing_products_to_shopify
        missing_products_internal_identifiers.each do |identifier|
          Shopify::Product::Exporter.new(retailer_id: retailer.id).perform(identifier)
        end
      end

      def shopify_products_ids
        Spree::ProductListing.where(
          retailer_id: retailer.id,
          product_id: local_products.ids
        ).pluck(:id)
      end

      def missing_products_internal_identifiers
        local_products.where(id: missing_products_ids).pluck(:internal_identifier)
      end
    end
  end
end
