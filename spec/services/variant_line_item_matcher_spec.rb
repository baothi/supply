require 'rails_helper'

RSpec.describe VariantLineItemMatcher, type: :service do
  let!(:retailer) { create :spree_retailer }
  let!(:supplier) { create :spree_supplier }
  let(:variant) { create :on_demand_spree_variant, is_master: false }
  let!(:line_item) { load_fixture('shopify/line_item') }
  let(:subject) { VariantLineItemMatcher.new(line_item, retailer) }

  let(:variant_listings) do
    create_list(:spree_variant_listing, 2, retailer: retailer, supplier_id: supplier.id)
  end
  let(:skus) { variant_listings.map(&:variant).map(&:platform_supplier_sku) }
  let(:shopify_product) do
    create(:shopify_cache_product,
           shopify_url: retailer.shopify_url,
           role: 'supplier',
           variants: [
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: variant.original_supplier_sku
               ),
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: skus[1]
               )
           ])
  end

  before do
    allow(retailer).to receive(:initialize_shopify_session!).and_return true
    allow(retailer).to receive(:destroy_shopify_session!).and_return true
    Mongoid.purge!
  end

  describe '#perform' do
    context 'when variant is found using variant listing' do
      before do
        create(
          :spree_variant_listing,
          variant: variant,
          shopify_identifier: line_item.variant_id,
          retailer_id: retailer.id,
          supplier_id: supplier.id
        )
      end

      it 'returns variant' do
        expect(subject.perform).to eq variant
      end

      it 'does not search for variant with other properties' do
        expect(subject).not_to receive(:variant_with_other_properties).with(line_item)
        subject.perform
      end
    end

    context 'when variant is not found using variant listing' do
      it 'searches for variant with other properties' do
        expect(subject).to receive(:variant_with_other_properties).with(line_item)
        subject.perform
      end
    end
  end

  describe '#retrieve_shopify_variant_from_retailer' do
    it 'looks for retailer shopify variant' do
      id = line_item.variant_id
      allow(subject).to receive(:retailer).and_return retailer
      expect(CommerceEngine::Shopify::Variant).to receive(:find).with(id)
      subject.retrieve_shopify_variant_from_retailer(id)
    end
  end

  describe '#get_variants_with_barcode_and_sku' do
    context 'when only barcode is present' do
      before do
        @options = { barcode: 'barcode' }
      end

      it 'returns array with variant if found' do
        variant.update(barcode: 'barcode')
        expect(subject.get_variants_with_barcode_and_sku(@options)).to include variant
      end

      it 'returns empty array if variant not found' do
        expect(subject.get_variants_with_barcode_and_sku(@options)).to eq []
      end
    end

    context 'when only supplier sku is present' do
      before do
        @options = { supplier_sku: 'sku' }
      end

      it 'returns array with variant if found' do
        variant.update(platform_supplier_sku: 'SKU')
        expect(subject.get_variants_with_barcode_and_sku(@options)).to include variant
      end

      it 'returns empty array if variant not found' do
        expect(subject.get_variants_with_barcode_and_sku(@options)).to eq []
      end
    end
  end

  describe '#return_eligible_variant' do
    before do
      variant.update(shopify_identifier: 'identifier')
    end

    it 'looks for variant on supplier shopify store' do
      results = [variant]
      expect(ShopifyCache::Variant).to receive(:locate_at_supplier).and_call_original
      subject.return_eligible_variant(results)
    end

    it 'returns eligible variant if found' do
      results = [variant]
      first_shopify_variant = shopify_product.variants.first
      allow(ShopifyCache::Variant).to receive(:locate_at_supplier).
        and_return [first_shopify_variant, shopify_product]
      expect(subject.return_eligible_variant(results)).to eq variant
    end

    it 'returns nil if no eligible variant if found' do
      results = [variant]
      allow(ShopifyCache::Variant).to receive(:find).and_return [nil, nil]
      expect(subject.return_eligible_variant(results)).to eq nil
    end
  end
end
