RSpec.shared_examples 'a model with inventory tracking capabilities' do
  before do
    Mongoid.purge!
  end

  describe '.available_quantity' do
    it 'returns 0 if platform_supplier_sku is nil' do
      expect(Spree::Variant.available_quantity(
               retailer: spree_retailer,
               platform_supplier_sku: nil
             )).to eq 0
    end

    it 'returns 0 if platform_supplier_sku is empty' do
      expect(Spree::Variant.available_quantity(
               retailer: spree_retailer,
               platform_supplier_sku: ''
             )).to eq 0
    end

    it 'returns 0 if supplier is not valid' do
      expect(Spree::Variant.available_quantity(
               retailer: spree_retailer,
               platform_supplier_sku: 'NONEEXISTING-SUPPLIERR$'
             )).to eq 0
    end

    it 'calls available_quantity_at_shopify for shopify suppliers' do
      allow_any_instance_of(Spree::Supplier).to receive(:shopify_supplier?).and_return(true)
      expect(Spree::Variant).to receive(:available_quantity_at_shopify)

      create(:spree_supplier, brand_short_code: 'HINGETO')

      Spree::Variant.available_quantity(
        retailer: spree_retailer,
        platform_supplier_sku: 'NONEEXISTING-HINGETO'
      )
    end

    it 'calls available_quantity_locally for non-shopify suppliers' do
      allow_any_instance_of(Spree::Supplier).to receive(:shopify_supplier?).and_return(false)

      expect(Spree::Variant).to receive(:available_quantity_locally)
      create(:spree_supplier, brand_short_code: 'HINGETO')

      Spree::Variant.available_quantity(
        retailer: spree_retailer,
        platform_supplier_sku: 'NONEEXISTING-HINGETO'
      )
    end
  end

  describe '.available_quantity_at_shopify' do
    it 'calls ShopifyCache::Product.quantity_on_hand' do
      expect(ShopifyCache::Product).to receive(:quantity_on_hand)
      Spree::Variant.available_quantity_at_shopify(
        supplier: spree_supplier,
        retailer: spree_retailer,
        original_supplier_sku: 'XXXXX',
        platform_supplier_sku: 'XXXXX'
      )
    end

    it 'returns the same quantity as calling ShopifyCache::Product.quantity_on_hand' do
      allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0

      spree_supplier.brand_short_code = 'SHORTCODE'
      spree_supplier.save

      product = create(:shopify_cache_product,
                       shopify_url: spree_supplier.shopify_url)

      variant = product.variants.first
      variant.update(inventory_quantity: 5, sku: 'XXXX-2')
      variant.reload

      quantity_on_hand =
        ShopifyCache::Product.quantity_on_hand(
          supplier: spree_supplier,
          original_supplier_sku: 'XXXX-2'
        )

      available_quantity_at_shopify =
        Spree::Variant.available_quantity_at_shopify(
          supplier: spree_supplier,
          retailer: nil,
          original_supplier_sku: 'XXXX-2',
          platform_supplier_sku: 'XXXX-2-SHORTCODE'
        )

      expect(available_quantity_at_shopify).to eq quantity_on_hand
    end
  end

  describe '.available_quantity_locally' do
    it 'returns 0 if not found a valid variant' do
      expect(
        Spree::Variant.available_quantity_locally(platform_supplier_sku: 'NON-EXISTENT')
      ).to eq 0
    end

    it 'returns the correct quantity' do
      variant = create(:on_demand_spree_variant, platform_supplier_sku: 'FOUNDSKU-BLAHBLAH')
      allow_any_instance_of(Spree::Variant).to receive(:legacy_available_quantity).and_return(3)
      expect(
        Spree::Variant.available_quantity_locally(
          platform_supplier_sku: variant.platform_supplier_sku
        )
      ).to eq 3
    end
  end

  describe '#available_quantity' do
    it 'calls the Shopify Cache service for Shopify Variants' do
      allow_any_instance_of(Spree::Supplier).to receive(:shopify_supplier?).and_return(true)

      variant = create(:on_demand_spree_variant)

      expect(Spree::Variant).to receive(:available_quantity_at_shopify)
      # expect(ShopifyCache::Product).to receive(:quantity_on_hand)
      expect(variant).not_to receive(:legacy_available_quantity)

      variant.available_quantity
    end

    it 'calls the local service for non-Shopify Variants' do
      allow_any_instance_of(Spree::Supplier).to receive(:shopify_supplier?).and_return(false)

      variant = create(:on_demand_spree_variant)

      expect(ShopifyCache::Product).not_to receive(:quantity_on_hand)
      expect(variant).to receive(:legacy_available_quantity)

      variant.available_quantity
    end
  end
end
