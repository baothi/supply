module Shopify
  module Variant
    class Exporter
      attr_accessor :retailer, :local_product, :errors, :logs, :shopify_product

      def initialize(opts = {})
        @local_product = opts[:local_product]
        @shopify_product = opts[:shopify_product]
        @retailer = opts[:retailer]

        @errors = ''
        @logs = ''
      end

      def perform
        shopify_product.variants.each { |shopify_variant| set_inventory(shopify_variant) }
        shopify_product.variants.each do |shopify_variant|
          export_variant_image(shopify_variant, shopify_product)
        end
        errors
      end

      def export_variant_image(shopify_variant, shopify_product)
        local_variant = local_product.variants.submission_compliant.find_by(
          platform_supplier_sku: shopify_variant.sku
        )
        logs << "Exporting variant image.\n"
        begin
          raise 'Invalid local variant' if local_variant.nil?

          first_image = local_variant.images.first
          if first_image.nil?
            logs << "No Image Found for Variant #{local_variant.id}. Skipping.\n"
            return
          end
          image = Shopify::Export::ImageExporter.new(image: first_image).perform
          image.prefix_options[:product_id] = shopify_product.id
          result = ShopifyAPIRetry.retry(5) { image.save }
          if result
            shopify_variant.image_id = image.id
            ShopifyAPIRetry.retry(5) { shopify_variant.save }
            logs << "Images for variant exported.\n"
          else
            errors << "Image saved.\n"
          end
        rescue => e
          errors << "#{e}.\n"
        end
      end

      def set_inventory(shopify_variant)
        local_variant = local_product.variants.submission_compliant.find_by(
          platform_supplier_sku: shopify_variant.sku
        )

        begin
          raise 'Invalid local variant' if local_variant.nil?

          inventory_item_id = shopify_variant.inventory_item_id

          inventory_level = ShopifyAPI::InventoryLevel.new(
            inventory_item_id: inventory_item_id,
            location_id: retailer.default_location_shopify_identifier # TODO ask and set this
          )
          ShopifyAPIRetry.retry(5) { inventory_level.set(local_variant.count_on_hand) }
        rescue => e
          errors << "#{e}.\n"
        end
      end
    end
  end
end
