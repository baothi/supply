module Shopify
  module Image
    class BulkImportJob < ApplicationJob
      queue_as :images_import

      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        force_download = @job.option_1
        supplier = Spree::Supplier.find_by(id: @job.supplier_id)
        supplier.init

        @products = supplier.products
        @job.update(total_num_of_records: @products.count)

        force_download == 't' ? download_from_shopify : download_from_url
      end

      def download_from_url
        ActiveRecord::Base.no_touching do
          @products.find_each(batch_size: 250) do |product|
            master_variant = product.master

            remove_images(master_variant)
            product.image_urls.each do |url|
              import_image(url, master_variant)
            end

            variants = product.variants
            variants.each do |variant|
              variant.image_urls.each do |url|
                remove_images(variant)
                import_image(url, variant)
              end
            end

            # Update Counter Cache
            product.update_image_counter!
            @job.update_status(true)
          end
        end
      end

      def download_from_shopify
        product_shopify_ids = @products.pluck(:shopify_identifier)

        product_shopify_ids.each_slice(250) do |product_ids|
          product_ids = product_ids.join(',')
          shopify_products = get_products(product_ids)
          next if shopify_products.empty?

          ActiveRecord::Base.no_touching do
            shopify_products.each do |shopify_product|
              variant_images =
                shopify_product.images.map { |i| { src: i.src, variant_ids: i.variant_ids } }
              product_images = shopify_product.images.map do |i|
                { src: i.src, product_id: i.prefix_options[:product_id] }
              end

              download_variant_images(variant_images)

              begin
                local_product = @products.find_by(shopify_identifier: shopify_product.id)
                product_image_urls = product_images.map { |i| i[:src] }
                local_product.update_columns(image_urls: product_image_urls)

                master_variant = local_product.master

                remove_images(master_variant)
              rescue => e
                error = "#{e} for #{shopify_product.title} \n"
                @job.log_error(error)
                next
              end

              product_image_urls.each do |url|
                import_image(url, master_variant)
              end

              # Update Counter Cache
              local_product.update_image_counter!
              @job.update_status(true)
            end
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
              error = "#{e} for #{shopify_product.title} => #{variant.internal_identifier} \n"
              @job.log_error(error)
              next
            end
          end
        end
      end

      def get_products(product_ids)
        begin
          CommerceEngine::Shopify::Product.find(:all, params: { ids: product_ids })
        rescue => e
          error = "#{e} \n"
          @job.log_error(error)
          []
        end
      end

      def import_image(url, variant)
        begin
          spree_image = Spree::Image.new(viewable: variant)
          spree_image.attachment = URI.parse(url)
          # temp solution for sole society
          spree_image.attachment_file_name = spree_image.attachment_file_name.gsub('.php', '.jpeg')
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
