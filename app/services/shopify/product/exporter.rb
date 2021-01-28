module Shopify
  module Product
    class Exporter
      attr_accessor :retailer, :local_product, :errors, :logs, :export_process

      def initialize(opts = {})
        @retailer_id = opts[:retailer_id]
        raise 'Retailer required for product export' if @retailer_id.nil?

        @retailer = Spree::Retailer.find_by(id: @retailer_id)

        @errors = ''
        @logs = ''
      end

      def set_export_process
        @export_process = Spree::ProductExportProcess.find_or_create_by(
          product_id: local_product.id,
          retailer_id: retailer.id
        )
        export_process.completed? ? export_process.restart! : export_process.begin_export!
      end

      def perform(product_id)
        @local_product = Spree::Product.find_by(internal_identifier: product_id)
        set_export_process

        product_listing = local_product.retailer_listing(retailer.id)
        begin
          if product_listing && product_listing.shopify_identifier.present?
            # This should kick off a product update job, makes more sense
            return true
          end

          shopify_product = local_product.shopify_params(@retailer)
          shopify_product[:variants] = []
          local_product.variants.submission_compliant.each do |variant|
            shopify_product[:variants] << variant.shopify_params(@retailer)
          end

          shopify_product = export_images(local_product, shopify_product)

          variants_count = shopify_product[:variants].length
          product = Shopify::GraphAPI::Product.new(retailer)
          result = product.create(shopify_product, variants_count)
          puts 'Results of adding process:'.red
          puts "#{result.inspect}".red

          exported_shopify_product = result.original_hash['data']['productCreate']['product']
          if exported_shopify_product.nil?
            Rollbar.warning("Issue adding product to #{retailer&.name}'s store",
                            retailer_id: retailer&.id,
                            product_id: local_product.internal_identifier,
                            product_name: local_product.name,
                            supplier_id: local_product.supplier&.id,
                            supplier_name: local_product.supplier&.name)
          end

          return false unless exported_shopify_product.present?

          shopify_identifier = Shopify::GraphAPI::Base.decode_id(
            exported_shopify_product['id'], 'Product'
          )

          if shopify_identifier.present?
            local_product.shopify_identifier = shopify_identifier
            local_product.save

            create_listings(exported_shopify_product, shopify_identifier)

            export_process.complete_export!
            return true
          else
            log_error_to_export_process 'Unable to export product to shopify'
            return false
          end
        rescue => ex
          log_error_to_export_process(ex)
          return false
        end
      end

      def log_error_to_export_process(log)
        begin
          puts "#{log}".red
          errors << log.to_s
          return if export_process.nil?

          export_process.log_error!(log)
          export_process.raise_issue!
        rescue => inner_ex
          puts "#{inner_ex}".red
          errors << inner_ex.to_s
        end
      end

      def create_listings(shopify_product, shopify_identifier)
        product_listing = local_product.create_listing(shopify_identifier, retailer.id)
        shopify_variants = shopify_product['variants']['edges']
        shopify_variants.each do |shopify_variant|
          id = Shopify::GraphAPI::Base.decode_id(
            shopify_variant['node']['id'], 'ProductVariant'
          )
          sku = shopify_variant['node']['sku']
          local_variant = local_product.variants.find_by(platform_supplier_sku: sku)
          local_variant.create_variant_listing(id, retailer.id, product_listing.id)
        end
      end

      def export_images(local_product, shopify_product)
        # Shopify GraphQL API requires live image url in src field
        shopify_product[:images] = []
        shopify_product[:images] = local_product.image_urls.map { |url| { src: url } }

        shopify_product
      end
    end
  end
end
