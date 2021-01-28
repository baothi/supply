module Shopify
  module Product
    class Importer
      attr_reader :errors, :logs, :team
      require 'open-uri'

      include Shopify::Helpers

      def validate(opts)
        raise 'Supplier is required'  if
            opts[:supplier].blank? && opts[:supplier_id].blank?
      end

      def initialize(opts = {})
        validate opts
        @supplier = opts[:supplier]
        @supplier ||= Spree::Supplier.find(opts[:supplier_id])
        @errors = ''
        @logs = ''
        @run_sync = opts[:run_sync]
        @download_images = opts[:download_images]
      end

      def perform_import(local_product, shopify_product)
        begin
          local_product = if local_product.new_record?
                            create_product(local_product, shopify_product)
                          else
                            update_product(local_product, shopify_product)
                          end

          @logs << "Product #{local_product.name} imported.\n"
          return local_product
        rescue => e
          @errors << "#{e} for product #{shopify_product.title}\n"
          @error = true
          return nil
        end
      end

      def perform(shopify_product)
        local_product = Spree::Product.
                        find_or_initialize_by(shopify_identifier: shopify_product.id)
        @logs << "Importing Product #{local_product.name}.\n"

        local_product = perform_import(local_product, shopify_product)
        return false if local_product.nil?

        if local_product.persisted?
          @logs << "Importing Variants for #{local_product.name}.\n"

          variant_errors = Shopify::Variant::Importer.
                           new(local_product: local_product,
                               shopify_product: shopify_product).perform

          if variant_errors.present?
            @logs << "#{variant_errors}\n"
            @errors << "#{variant_errors}\n"
          end
          @logs << "Finished variant import for #{local_product.name}.\n"

          local_product.update_search_attributes!

          get_image_urls(shopify_product, local_product)
          true
        else
          false
        end
      end

      def create_product(local_product, shopify_product)
        default_category = Spree::ShippingCategory.first
        default_category ||= Spree::ShippingCategory.create!(name: 'Default')

        local_product.update_attributes(
          name: shopify_product.title,
          description: shopify_product.body_html,
          available_on: shopify_product.published_at,
          shopify_identifier: shopify_product.id,
          discontinue_on: nil,
          supplier_id: @supplier.id,
          shipping_category: default_category, # Todo Set Shipping Category
          price: product_price(shopify_product, @supplier),
          license_name: shopify_product.vendor,
          shopify_vendor: shopify_product.vendor,
          shopify_product_type: shopify_product.product_type
        )
        local_product.save!
        local_product
      end

      def update_product(local_product, shopify_product)
        discontinue_on = shopify_product.published_at.present? ? nil : DateTime.now

        local_product.update_attributes(
          name: shopify_product.title,
          description: shopify_product.body_html,
          available_on: shopify_product.published_at,
          discontinue_on: discontinue_on,
          price: product_price(shopify_product, @supplier),
          license_name: shopify_product.vendor,
          shopify_vendor: shopify_product.vendor,
          shopify_product_type: shopify_product.product_type
        )
        local_product.save!
        local_product
      end

      def get_image_urls(shopify_product, local_product)
        return if shopify_product.images.blank?

        variant_images =
          shopify_product.images.map { |i| { src: i.src, variant_ids: i.variant_ids } }
        product_images = shopify_product.images.map do |i|
          { src: i.src, product_id: shopify_product.id }
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

        # Now download images
        return unless ENV['DOWNLOAD_SHOPIFY_IMAGES'] == 'true' && @download_images

        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'images_import',
          initiated_by: 'user',
          option_1: local_product.id
        )
        if @run_sync
          Shopify::ImportProductImageJob.new.perform(job.internal_identifier)
        else
          Shopify::ImportProductImageJob.perform_later(job.internal_identifier)
        end
      end

      def attach_image(obj_id, url, obj_type)
        klass = obj_type.constantize
        return unless klass

        obj = klass.find_by(shopify_identifier: obj_id)
        return unless obj

        obj.image_urls << url unless obj.image_urls.include? url

        obj.save!
      end

      def generate_csv(rows)
        CSV.open("#{Rails.root}/tmp/#{@job.internal_identifier}.csv", 'wb') do |csv|
          rows.each do |row|
            csv << row
          end
        end
        file = File.open("#{Rails.root}/tmp/#{@job.internal_identifier}.csv")
        file
      end
    end
  end
end
