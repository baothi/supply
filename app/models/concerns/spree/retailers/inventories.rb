module Spree::Retailers::Inventories
  extend ActiveSupport::Concern

  included do
    scope :inventory_generated_more_than_15_mins_ago, -> {
      joins(:retailer_inventory).where(
        'spree_retailer_inventories.last_generated_at < :last_generated_at',
        last_generated_at: DateTime.now - 15.minutes
      )
    }

    scope :inventory_generated_more_than_an_hour_ago, -> {
      joins(:retailer_inventory).where(
        'spree_retailer_inventories.last_generated_at < :last_generated_at',
        last_generated_at: DateTime.now - 60.minutes
      )
    }

    has_one :retailer_inventory, dependent: :destroy
  end

  def generate_inventories!
    variants_hash = {}
    ShopifyCache::Product.shopify_retailer_products(retailer: self).each do |shopify_product|
      shopify_product.variants.each do |shopify_variant|
        variant = Spree::Variant.locate_hingeto_variant(
          platform_supplier_sku: shopify_variant.sku
        )
        next if variant.nil?

        variants_hash[shopify_variant.sku] = variant.available_quantity(retailer: self)
      end
    end

    # Obtain inventory record
    record = self.inventory_record
    record.inventory = variants_hash
    record.last_generated_at = DateTime.now
    record.save!
  end

  def inventory_record
    begin
      Spree::RetailerInventory.find_or_create_by!(retailer_id: self.id)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  def json_inventory
    inventory_record.inventory
  end
end
