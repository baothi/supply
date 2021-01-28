module Spree::ProductListings::AdminSearchable
  extend ActiveSupport::Concern

  included do
    # scope :license_name_is, ->(search) { Spree::Product.search_by_license_name(search) }
    # scope :product_id_equals, ->(product_id) { search_by_product_id(product_id) }
  end

  class_methods do
    # For ActiveAdmin

    # def search_by_retailer_id(license_name)
    #   Spree::Retailer.where("spree_products.license_name ilike '%#{license_name}%'")
    # end
    #
    def search_by_product_id(product_id)
      # Spree::ProductListing.where(product_id: product_id)
    end

    # def ransackable_scopes(auth_object = nil)
    #   # [:product_id_equals]
    # end

    # def ransackable_attributes(_auth_object = nil)
    #   %w(product_id) + _ransackers.keys
    # end
  end
end
