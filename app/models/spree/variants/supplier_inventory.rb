module Spree::Variants::SupplierInventory
  extend ActiveSupport::Concern

  class_methods do
    def available_quantity(retailer:, platform_supplier_sku:)
      return 0 if platform_supplier_sku.blank?

      sku_parts =
        Spree::Variant.derive_sku_components(platform_supplier_sku: platform_supplier_sku)

      supplier = Spree::Supplier.where(brand_short_code: sku_parts[:brand_short_code]).first
      return 0 if supplier.nil?

      # binding.pry

      if supplier.shopify_supplier?
        available_quantity_at_shopify(
          supplier: supplier,
          retailer: retailer,
          original_supplier_sku: sku_parts[:original_supplier_sku],
          platform_supplier_sku: platform_supplier_sku
        )
      else
        available_quantity_locally(platform_supplier_sku: platform_supplier_sku)
      end
    end

    def available_quantity_at_shopify(
        supplier:,
        retailer:,
        original_supplier_sku:,
        platform_supplier_sku:
      )
      ShopifyCache::Product.quantity_on_hand(
        supplier: supplier,
        retailer: retailer,
        original_supplier_sku: original_supplier_sku,
        platform_supplier_sku: platform_supplier_sku
      )
    end

    def available_quantity_locally(platform_supplier_sku:)
      val = Spree::Variant.where(
        platform_supplier_sku: platform_supplier_sku
      ).order('created_at desc').first&.legacy_available_quantity
      val.to_i
    end
  end
end
