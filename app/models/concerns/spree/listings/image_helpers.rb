# Used by VariantListing.
module Spree::Listings::ImageHelpers
  extend ActiveSupport::Concern

  included do
    def listing_image(image_index = 1, style = :large)
      if images.present?
        images.first&.attachment&.url(style)
      elsif product.present? && product.images.present?
        product.images.find_by(position: image_index)&.attachment&.url(style)
      end
    end

    def active_admin_mini_image
      if images.present?
        images.first&.attachment&.url(:mini)
      elsif product.present? && product.images.present?
        product.images.first&.attachment&.url(:mini)
      end
    end

    def mini_image(image_index = 1)
      listing_image(image_index, :mini)
    end

    def small_image(image_index = 1)
      listing_image(image_index, :small)
    end

    def product_image(image_index = 1)
      listing_image(image_index, :product)
    end

    def large_image(image_index = 1)
      listing_image(image_index, :large)
    end

    def product_images_count
      product.images.count
    end

    def variant_images_count
      variant.images.count
    end

    def images_count
      return variant_images_count if variant.images.present?

      product_images_count
    end
  end
end
