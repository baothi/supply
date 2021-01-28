module Spree::Products::AdminSearchable
  extend ActiveSupport::Concern

  included do
    # scope :license_name_is, ->(search) { Spree::Product.search_by_license_name(search) }
    # scope :submission_state_is, ->(search) { Spree::Product.search_by_submission_state(search) }
    scope :with_images, -> {
      where('image_counter > 0')
    }

    scope :without_images, -> {
      where('image_counter = 0')
    }
  end

  class_methods do
    # For ActiveAdmin

    # def search_by_license_name(license_name)
    #   Spree::Product.where("spree_products.license_name ilike '%#{license_name}%'")
    # end
    #
    # def search_by_submission_state(submission_state)
    #   Spree::Product.where("spree_products.submission_state ilike '%#{submission_state}%'")
    # end

    # def ransackable_scopes(_auth_object = nil)
    #   %i(license_name_is submission_state_is)
    # end

    def ransackable_attributes(_auth_object = nil)
      %w(name internal_identifier
         license_name submission_state supplier_id supplier_brand_name
         image_counter) +
        _ransackers.keys
    end
  end
end
