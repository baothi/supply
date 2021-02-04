class Spree::VariantCostVersion < PaperTrail::Version
  self.table_name = :variant_cost_versions
end

class Spree::VariantCost < ApplicationRecord
  has_paper_trail versions: { class_name: 'Spree::VariantCostVersion' }

  include Unremovable

  # After Commit
  include CommitWrap

  belongs_to :supplier, class_name: 'Spree::Supplier'

  validates_presence_of :sku,
                        :msrp,
                        :cost,
                        :supplier

  validate :msrp_greater_than_cost

  before_validation :strip_sku
  before_validation :upcase_sku
  after_commit :syndicate_cost_changes_to_variants!
  after_update :update_shopify_metafields,  if: proc { cost_changed? }

  MASTER_SHEET = 'master_sheet'.freeze
  SHOPIFY = 'shopify'.freeze
  UPLOAD = 'upload'.freeze

  def strip_sku
    self.sku = self.sku&.strip
  end

  def upcase_sku
    self.sku = self.sku&.upcase
  end

  def supplier_name
    supplier&.name
  end

  def msrp_greater_than_cost
    errors.add(:msrp, 'Must be greater than cost') if msrp.to_f <= cost.to_f
    errors.add(:cost, 'Must be less than MSRP') if msrp.to_f < cost.to_f
  end

  # TODO: Work in progress
  def special_variant_costs
    Spree::SpecialVariantCost.where(
      sku: sku,
      supplier: supplier
    )
  end

  def syndicate_cost_changes_to_variants!
    props = {
        price_management: Spree::VariantCost::MASTER_SHEET,
        cost_price: self.cost,
        msrp_price: self.msrp
    }
    if self.minimum_advertised_price.present?
      props.deep_merge(map_price: self.minimum_advertised_price)
    end

    # Update variant
    variants.update_all(props)
  end

  def variants
    Spree::Variant.where(
      'supplier_id = :supplier_id and upper(original_supplier_sku) = :original_supplier_sku',
      supplier_id: self.supplier_id,
      original_supplier_sku: self.sku
    )
  end

  # TODO: Can be broken up to use background job.
  def self.update_costs_for_all_suppliers
    Spree::Supplier.find_each do |supplier|
      puts "Updating costs for #{supplier.id}".blue
      update_costs_for_supplier(supplier.id)
    end
  end

  def self.update_costs_for_supplier(supplier_id)
    Spree::VariantCost.where(supplier_id: supplier_id).find_each do |variant_cost|
      variant_cost.variants.update_all(
        price_management: Spree::VariantCost::MASTER_SHEET,
        cost_price: variant_cost.cost,
        msrp_price: variant_cost.msrp,
        map_price: variant_cost.minimum_advertised_price
      )
    end
  end

  def update_shopify_metafields
    ActiveRecord::Base.transaction do
      job = create_product_metafield_update_job
      execute_after_commit do
        Shopify::ProductMetafieldsUpdateWorker.perform_async(job.internal_identifier)
      end
    end
  end

  def create_product_metafield_update_job
    Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'system',
      option_2: id
    )
  end
end
