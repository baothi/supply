# Used by VariantListing.
module Spree::Products::SearchScope
  extend ActiveSupport::Concern

  included do
    SEARCH_ATTRS = %w(Any SKU Name Description).freeze

    scope :filter, ->(filter_key) do
      next if filter_key == 'all'

      send(filter_key) if filter_key.present? && respond_to?(filter_key)
    end

    scope :by_supplier, ->(supplier_id) {
      puts "Looking for products where supplier_id = #{supplier_id}".red
      where('spree_products.supplier_id = ?', supplier_id)
    }

    scope :by_retailer, ->(retailer_id) {
      where('spree_products.retailer_id = ?', retailer_id)
    }

    scope :from_created, ->(from) {
      where('spree_products.created_at >= :from', from: from)
    }

    # TODO: Refactor to use Algolia or ElasticSearch
    scope :search_all, ->(search_value) {
      return unless search_value.present?

      sql = '
      LOWER(spree_products.name) LIKE :q OR
      LOWER(spree_products.description) LIKE :q OR
      LOWER(spree_products.meta_title) LIKE :q OR
      LOWER(spree_products.meta_description) LIKE :q
      '
      sku(search_value).
        or(joins(:variants_including_master).where(sql, q: "%#{search_value.downcase}%"))
    }

    scope :search_by, ->(field, search_value) {
      return sku(search_value) if field == 'sku'

      where("LOWER(spree_products.#{field}) LIKE :q", q: "%#{search_value.downcase}%")
    }

    scope :to_created, ->(to) {
      where('spree_products.created_at <= :to', to: to)
    }

    scope :sku, ->(sku) {
      joins(:variants_including_master).where(
        'spree_variants.sku LIKE :q OR spree_variants.platform_supplier_sku LIKE :q', q: "%#{sku}%"
      )
    }

    scope :apply_order, ->(sort_order) {
      return order(created_at: :desc) if sort_order == 'recent'
      return ascend_by_master_price if sort_order == 'price_lowest'

      descend_by_master_price if sort_order == 'price_highest'
    }

    scope :apply_search, ->(params) {
      field = params[:search_field]
      return search_all(params[:search_value]) if field.blank? || field.casecmp('any').zero?

      search_by(field.downcase, params[:search_value])
    }

    scope :listed_for_retailer, ->(retailer_id) do
      joins(:product_listings).
        where('spree_product_listings.retailer_id = ?', retailer_id)
    end

    # Similiar to the !listed_for_retailer, but avoids a JOIN to allow us to use for complex
    # queries using textacular gem
    # Is less than ideal because it uses two queries.
    scope :not_in_retailer_shopify, ->(retailer) do
      where('spree_products.id NOT in (?)', retailer.products_ids_for_added_listings)
    end

    scope :in_multiple_taxons, ->(*taxons) do
      products = self
      taxons.each_with_index do |taxon, i|
        tx = "taxon_#{i}"
        products = products.joins(
          "INNER JOIN spree_products_taxons #{tx} ON #{tx}.product_id= spree_products.id"
        )
        products = products.where(
          "#{tx}.taxon_id IN (:#{tx})", "#{tx}": taxon.self_and_descendants.pluck(:id)
        )
      end
      products
    end
  end

  class_methods do
  end
end
