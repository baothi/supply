module Shopify
  module FulfillmentService
    class FetchStock
      attr_accessor :platform_supplier_sku, :shop, :retailer, :res

      def initialize(opts = {})
        @shop = opts[:shop]
        raise 'Shop must be present' if @shop.blank?

        @platform_supplier_sku = opts[:sku]
        @retailer = Spree::Retailer.find_by(shopify_url: shop)
        @res = {}
      end

      def perform
        # res = {}
        if platform_supplier_sku.present?
          variant = get_variant
          count_on_hand = 0
          if variant.present?
            count_on_hand = variant.available_quantity(retailer: retailer)
          else
            Rollbar.warning("Cannot find #{platform_supplier_sku}. Looking for #{shop}")
          end
          self.res[platform_supplier_sku] = count_on_hand
        else
          self.res = retailer.present? ? retailer.json_inventory : {}
        end
        res
      end

      private

      def get_variant
        Spree::Variant.where(
          'LOWER(platform_supplier_sku) = :platform_supplier_sku',
          platform_supplier_sku: platform_supplier_sku.downcase
        ).order('created_at desc').first
      end
    end
  end
end
