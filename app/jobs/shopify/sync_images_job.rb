module Shopify
  class SyncImagesJob < ApplicationJob
    queue_as :images_import

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        raise 'Invalid Job' if @job.nil?

        @job.begin_job!
      rescue => ex
        @job.raise_issue!
        @job.log_error("#{ex} \n")
        return
      end

      begin
        product_listing = Spree::ProductListing.find_by(internal_identifier: @job.option_1)

        retailer = product_listing.retailer
        product = product_listing.product
        product_shopify_id = product_listing.shopify_identifier

        retailer.init

        shopify_product = CommerceEngine::Shopify::Product.find(product_shopify_id)
        shopify_variants = ShopifyAPIRetry.retry(5) { shopify_product.variants }

        export_product_images(product, shopify_product)

        shopify_variants.each do |shopify_variant|
          local_variant = Spree::VariantListing.find_by(
            shopify_identifier: shopify_variant.id
          ).variant
          export_variant_image(local_variant, shopify_variant)
        end
        @job.complete_job!
      rescue => ex
        @job.raise_issue!
        @job.log_error("#{ex} \n")
      end
    end

    def export_variant_image(local_variant, shopify_variant)
      begin
        first_image = local_variant.images.first
        if first_image.nil?
          return
        end

        image = Shopify::Export::ImageExporter.new(image: first_image).perform
        image.prefix_options[:product_id] = shopify_product.id
        result = ShopifyAPIRetry.retry(5) { image.save }
        if result
          shopify_variant.image_id = image.id
          ShopifyAPIRetry.retry(5) {  shopify_variant.save }

        end
      rescue => e
        @job.log_error("#{e} \n")
      end
    end

    def export_product_images(local_product, shopify_product)
      begin
        images = shopify_product.images
        images.each do |image|
          ShopifyAPIRetry.retry(3) { image.destroy }
        end
        shopify_product.images = []
      rescue
        shopify_product.images = []
      end
      local_product.images.each do |img|
        begin
          image = Shopify::Export::ImageExporter.new(image: img).perform
          shopify_product.images << image
        rescue => e
          @job.log_error("#{e} \n")
        end
      end

      ShopifyAPIRetry.retry(5) { shopify_product.save }
    end
  end
end
