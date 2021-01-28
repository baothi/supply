module Shopify
  module Image
    class SingleImportJob < ApplicationJob
      queue_as :images_import

      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?

        @product = Spree::Product.find_by(id: @job.option_1)
        return unless @product.present?

        supplier = @product.supplier
        return unless supplier

        # Initialize Shopify
        supplier.init

        download_from_shopify

        # Update Image Counter
        @product.update_image_counter!
      end

      def download_from_shopify
        ActiveRecord::Base.no_touching do
          begin
            shopify_product = ShopifyAPIRetry.retry(3) do
              ShopifyAPI::Product.find(@product.shopify_identifier)
            end
            variant_images =
              shopify_product.images.map { |i| { src: i.src, variant_ids: i.variant_ids } }
            product_images = shopify_product.images.map do |i|
              { src: i.src, product_id: i.prefix_options[:product_id] }
            end

            download_variant_images(variant_images)

            product_image_urls = product_images.map { |i| i[:src] }
            @product.update_columns(image_urls: product_image_urls)

            master_variant = @product.master

            remove_images(master_variant)
          rescue => e
            error = "#{e} for #{shopify_product&.title ||
                    ('Shopify product' + @product.shopify_identifier)} \n"
            @job.log_error(error)
            next
          end

          product_image_urls.each do |url|
            import_image(url, master_variant)
          end
        end
      end

      def download_variant_images(variant_images)
        variant_images.each do |image|
          url = image[:src]
          variant_ids = image[:variant_ids]

          variant_ids.each do |variant_shopify_id|
            begin
              variant = Spree::Variant.find_by(shopify_identifier: variant_shopify_id)
              variant.update_columns(image_urls: [url])
              remove_images(variant)
              import_image(url, variant)
            rescue => e
              error = "#{e} => #{variant.internal_identifier} \n"
              @job.log_error(error)
              next
            end
          end
        end
      end

      def import_image(url, variant)
        begin
          spree_image = Spree::Image.new(viewable: variant)
          spree_image.attachment = URI.parse(url)
          spree_image.save!
        rescue => e
          error = "#{e} \n"
          @job.log_error(error)
        end
      end

      def remove_images(variant)
        spree_images = Spree::Image.where(viewable: variant)
        spree_images.destroy_all if spree_images.present?
      end
    end
  end
end
