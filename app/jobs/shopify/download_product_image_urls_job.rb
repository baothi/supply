module Shopify
  class DownloadProductImageUrlsJob < ApplicationJob
    queue_as :images_import

    def perform(job_id)
      # We need to minimize callbacks
      ActiveRecord::Base.no_touching do
        execute_job(job_id)
      end
    end

    def execute_job(job_id)
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
        local_product = Spree::Product.find_by(internal_identifier: @job.option_1)

        supplier = local_product.supplier
        supplier.init

        shopify_product = ShopifyAPIRetry.retry(3) do
          ShopifyAPI::Product.find(local_product.shopify_identifier)
        end
        if shopify_product.present? && shopify_product.images.empty?
          puts "Product #{local_product.id} with Shopify Identifier: "\
            "#{local_product.shopify_identifier} does not have any images. Skipping!".yellow
          return
        end
        remove_previous_local_images(local_product)

        local_product.reload

        attach_all_images(shopify_product)

        # Now download images
        kickoff_image_downloads(local_product)

        @job.complete_job!
      rescue => e
        @job.log_error("#{e} \n")
      end
    end

    def kickoff_image_downloads(local_product)
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'images_import',
        initiated_by: 'user',
        option_1: local_product.id
      )

      Shopify::ImportProductImageJob.perform_later(job.internal_identifier)
    end

    def attach_all_images(shopify_product)
      shopify_product_images = shopify_product.images
      variant_images =
        shopify_product_images.map { |i| { src: i.src, variant_ids: i.variant_ids } }
      product_images = shopify_product_images.map do |i|
        { src: i.src, product_id: i.prefix_options[:product_id] }
      end

      variant_images.each do |image|
        url = image[:src]
        variant_ids = image[:variant_ids]

        variant_ids.each { |variant_id| attach_image(variant_id, url, 'Spree::Variant') }
      end

      product_images.each do |image|
        url = image[:src]
        product_id = image[:product_id]

        attach_image(product_id, url, 'Spree::Product')
      end
    end

    def attach_image(obj_id, url, obj_type)
      klass = obj_type.constantize
      return unless klass

      obj = klass.find_by(shopify_identifier: obj_id)
      return unless obj

      image_urls = obj.image_urls
      image_urls << url unless image_urls.include? url

      obj.update_columns(image_urls: image_urls)

      # obj.image_urls << url unless obj.image_urls.include? url
    end

    def remove_previous_local_images(local_product)
      local_product.images.destroy_all
      local_product.variants.each do |v|
        v.images.destroy_all
        v.update_columns(image_urls: [])
      end
      local_product.update_columns(image_urls: [])
    end
  end
end
