module Shopify
  module Export
    class ImageExporter
      require 'open-uri'
      def initialize(opts)
        validate(opts)
        @image = opts[:image]
      end

      def perform
        if Rails.env.development?
          file_path = "#{Rails.root}/public#{@image.attachment.url(:original, timestamp: false)}"
          file = File.read(file_path)
          image = ShopifyAPI::Image.new
          image.attach_image(file)
        elsif Rails.env.production?
          image = ShopifyAPI::Image.new(src: @image.attachment.url(:original))
        end
        image
      end

      def validate(opts)
        raise 'Image not found' if opts[:image].blank?
      end
    end
  end
end
