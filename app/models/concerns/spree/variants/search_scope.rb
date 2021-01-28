# Used by VariantListing.
module Spree::Variants::SearchScope
  extend ActiveSupport::Concern

  included do
    scope :by_supplier, ->(supplier_id) {
      where('spree_variants.supplier_id = ?', supplier_id)
    }

    scope :by_retailer, ->(retailer_id) {
      where('spree_variants.retailer_id = ?', retailer_id)
    }

    scope :from_created, ->(from) {
      where('spree_variants.created_at >= :from', from: from)
    }

    # TODO: Refactor to use Algolia or ElasticSearch
    scope :search_by, ->(search_by) {
      return unless search_by.present?

      sql = '
      LOWER(spree_variants.sku) LIKE :q OR
      LOWER(spree_variants.shopify_identifier) LIKE :q
      '
      joins(:variant).where(sql, q: "%#{search_by.downcase}%")
    }

    scope :to_created, ->(to) {
      where('spree_variants.created_at <= :to', to: to)
    }
  end
end
