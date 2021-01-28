module Spree::Products::CategoryOptionable
  extend ActiveSupport::Concern

  included do
    belongs_to :platform_category_option
    belongs_to :supplier_category_option

    after_commit :create_supplier_category_option_for_new_product

    scope :with_supplier_category_mapping, ->(supplier_category_option_id) {
      where('spree_products.supplier_category_option_id = :supplier_category_option_id',
            supplier_category_option_id: supplier_category_option_id)
    }

    scope :not_mapped_to_platform_category, -> {
      where('spree_products.platform_category_option_id is NULL')
    }

    scope :mapped_to_platform_category, -> {
      where('spree_products.platform_category_option_id is not NULL')
    }
  end

  def product_type
    return self.supplier_product_type unless self.supplier_product_type.blank?
    return self.shopify_product_type unless self.shopify_product_type.blank?
  end

  def create_supplier_category_option_for_new_product
    return if self.product_type.nil?
    return if self.supplier.nil?

    category_name = self.product_type
    category_name = category_name.strip

    Spree::SupplierCategoryOption.find_or_create_by!(name: category_name,
                                                     supplier: self.supplier) do |supplier_category|
      supplier_category.presentation = category_name
    end
  end

  def refresh_taxons_based_on_platform!
    taxons.destroy_all

    return if platform_category_option.nil?

    taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Platform Category')
    root_taxon ||= Spree::Taxon.find_or_create_by(name: 'Platform Category')

    to_assign = Spree::Taxon.find_or_create_by!(
      name: platform_category_option.name,
      taxonomy: taxonomy,
      parent: root_taxon
    )

    return if self.taxons.include?(to_assign)

    self.taxons << to_assign
    self.save!
  end
end
