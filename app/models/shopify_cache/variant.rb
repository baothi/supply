# The purpose of this model is to serve as a global index
# of all approved Hingeto Variants
class ShopifyCache::Variant
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  include ShopifyCache::Variants::Fields

  # Indices
  index({ 'lower_sku': 1 }, background: true)
  index({ 'lower_sku': 1, role: 1, shopify_url: 1 }, background: true)
  index({ 'lower_sku': 1, 'product_id': 1 }, background: true)
  index({ 'lower_barcode': 1 }, background: true)
  index({ role: 1, shopify_url: 1,
          'lower_sku': 1,
          created_at: -1 }, background: true)
  # Should be most commonly used.
  index({ deleted: 1, role: 1, shopify_url: 1,
          'lower_sku': 1, product_published_at: 1,
          created_at: -1 }, background: true)


  # Exclude deleted products
  default_scope -> { where(product_deleted_at: nil) }

  before_validation :save_lowercase_identifiers

  def self.locate_variants_by_sku(
      supplier:,
      original_supplier_sku:,
      include_unpublished: false
  )
    return [] if original_supplier_sku.blank?

    search_hash =
        {
            'role' => 'supplier',
            'shopify_url' => supplier.shopify_url,
            'lower_sku' => "#{original_supplier_sku}".downcase

        }
    search_hash.deep_merge!(:product_published_at.nin => ['', nil]) unless include_unpublished
    results = where(search_hash).order('created_at desc')
    results
  end

  # Returns the found variant and product.
  # This is because sometimes we need properties from both
  def self.locate_at_supplier(supplier:, original_supplier_sku:, include_unpublished: false)
    shopify_variant = locate_variants_by_sku(
      supplier: supplier,
      original_supplier_sku: original_supplier_sku,
      include_unpublished: include_unpublished
    ).first
    return [nil, nil] if shopify_variant.nil?
    shopify_product = ShopifyCache::Product.where(id: shopify_variant.product_id.to_i).first
    [shopify_variant, shopify_product]
  end

  def do_not_track_inventory?
    self.inventory_management.nil? || self.inventory_policy == 'continue'
  end

  def track_inventory?
    !do_not_track_inventory?
  end

  def save_lowercase_identifiers
    self.lower_sku = self.sku&.downcase
    self.lower_barcode = self.barcode&.downcase
  end
end
