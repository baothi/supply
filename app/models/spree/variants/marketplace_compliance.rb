module Spree::Variants::MarketplaceCompliance
  extend ActiveSupport::Concern

  include Spree::ProductsAndVariants::Compliantable

  def run_submission_compliance_check
    # Clear out any existing issues
    init_compliance_issues

    # SKU related
    ensure_sku_compliance
    ensure_variant_has_sku
    ensure_variant_has_unique_sku
    # ensure_images_compliance

    # Supplier Size / Color / Category
    ensure_has_supplier_size
    ensure_has_supplier_color

    # MSRP / Costs
    ensure_has_msrp
    ensure_has_costs
    ensure_has_msrp_is_less_than_cost

    ensure_minimum_inventory_available
  end

  def run_marketplace_compliance_check
    # Supplier Size / Color / Category
    ensure_has_platform_color
    ensure_has_platform_size
  end

  def ensure_sku_compliance
    ensure_variant_has_sku
    ensure_variant_has_unique_sku
  end

  def ensure_variant_has_sku
    add_submission_compliance_issue(I18n.t('products.compliance.variants_require_skus')) if
        self.original_supplier_sku.blank?
  end

  def ensure_variant_has_unique_sku
    add_submission_compliance_issue(sku_uniqueness_requirement_complaint) if
        self.original_supplier_sku.present? && !self.has_unique_supplier_sku?
  end

  def sku_uniqueness_requirement_complaint
    I18n.t('products.compliance.variants_require_unique_skus',
           sku: self.original_supplier_sku)
  end

  # Images Compliance

  def ensure_images_compliance
    add_submission_compliance_issue(I18n.t('products.compliance.requires_images')) unless
        self.has_images?
  end

  # Supplier Values
  def ensure_has_supplier_color
    add_submission_compliance_issue('Supplier color value cannot be blank') if
        self.supplier_color_value.blank?
  end

  def ensure_has_supplier_size
    add_submission_compliance_issue('Supplier size value cannot be blank') if
        self.supplier_size_value.blank?
  end

  def ensure_has_msrp
    add_submission_compliance_issue('MSRP is required - Please add to master file') if
        self.master_msrp.blank?
  end

  def ensure_has_costs
    add_submission_compliance_issue('Cost is required - Please add to master file') if
        self.master_cost.blank?
  end

  def ensure_has_msrp_is_less_than_cost
    add_submission_compliance_issue('MSRP must be greater than cost') if
        self.cost_price.to_f > self.msrp_price.to_f
  end

  # Platform Values
  def ensure_has_platform_color
    add_marketplace_compliance_issue('Platform color value cannot be blank') if
        self.platform_color_option.blank?
  end

  def ensure_has_platform_size
    add_marketplace_compliance_issue('Platform size value cannot be blank') if
        self.platform_size_option.blank?
  end

  # Inventory

  def ensure_minimum_inventory_available
    complain_about_inventory if self.available_quantity < 1
  end

  def complain_about_inventory
    add_submission_compliance_issue(I18n.t('products.compliance.minimum_inventory_required',
                                           num: self.count_on_hand,
                                           sku: self.original_supplier_sku))
  end
end
