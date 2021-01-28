# The purpose of this model is to serve as a global index
# of all Product in Retailer/Supplier stores
#
# It is primarily used to search in Supplier stores.
class ShopifyCache::Product
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embeds_many :variants, class_name: 'ShopifyCache::ProductVariant', inverse_of: :product

  include ShopifyCache::Products::Fields
  include ShopifyCache::Products::ProductVariants
  include ShopifyCache::Products::Variants
  include ShopifyCache::Products::Deletable

  index({ handle: 1 }, background: true)
  index({ shopify_url: 1, role: 1 }, background: true)
  index({ deleted_at: 1, last_generated_variants_at: 1 }, background: true)
  index({ 'variants.sku': 1 }, background: true)
  index({ 'variants.barcode': 1 }, background: true)
  index({ deleted_at: 1, role: 1, shopify_url: 1,
          created_at: -1 }, background: true)


  # Default Search parameter
  def self.variant_search_params(supplier:, sku:, role: 'supplier', include_unpublished: false)
    search_hash  = {
          'shopify_url' => supplier.shopify_url,
          'role' => role,
          'lower_sku': "#{sku}".downcase
      }

    search_hash.deep_merge!(:product_published_at.nin => ['', nil]) unless include_unpublished
    search_hash
  end

  def self.quantity_on_hand(
      supplier:,
      original_supplier_sku:,
      platform_supplier_sku: nil,
      retailer: nil
    )
    return 0 if supplier.nil? || original_supplier_sku.blank?

    variant = ShopifyCache::Variant.where(
        variant_search_params(
            supplier: supplier,
            sku: original_supplier_sku,
            role: 'supplier'
        )
    ).first
    return 0 if variant.nil?

    product = ShopifyCache::Product.where(id: variant.product_id).first
    return 0 if should_return_zero_for_quantity?(product: product)

    # When supplier has inventory tracking set to deny,
    # we assume they have an unlimited amount
    return 1000 if inventory_tracking_is_shut_off?(variant: variant)

    final_count =
      return_adjusted_quantity(quantity: variant.inventory_quantity,
                               supplier: supplier,
                               num_unfulfilled_orders: 0)
    final_count
  end

  # TODO: We will want to deal with unpublished products differently and not here in
  # in the future
  def self.should_return_zero_for_quantity?(product:)
    return true if product.nil? #|| product.published_at.nil? || product.deleted_at.present?

    false
  end

  def self.inventory_tracking_is_shut_off?(variant:)
    # Continue means do not track inventory
    # deny means do not sell if inventory falls below 0
    return true if
        variant.inventory_policy == 'continue' ||
        variant.inventory_management.nil?

    false
  end

  def self.return_adjusted_quantity(quantity:, supplier:, num_unfulfilled_orders: 0)
    supplier_buffer = (supplier&.setting_inventory_buffer).to_i
    final_count = (quantity - supplier_buffer) + num_unfulfilled_orders
    return final_count if final_count.positive?

    0
  end

  def self.shopify_retailer_products(retailer:)
    return [] if retailer.blank?

    where(role: 'retailer', shopify_url: retailer.shopify_url)
  end

end
