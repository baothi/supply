require 'rails_helper'

RSpec.describe Spree::Variant, type: :model do
  subject { build(:spree_variant) }

  it_behaves_like 'an internal_identifiable model'
  it_behaves_like 'a model with inventory tracking capabilities'
  it_behaves_like 'it respects filter scope for variants'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end

  describe 'scopes' do
    before do
      @variants = create_list(:spree_variant, 5)
    end

    describe 'from_created' do
      it 'selects variants with created from the date given upwards' do
        variant = create(:spree_variant)
        variant2 = @variants.last
        variant2.created_at = Date.today - 20.days
        expect(Spree::Variant.from_created(variant.created_at)).to include(variant)
      end

      it 'does not select variants whose created_at is not within date given upwards' do
        variant = create(:spree_variant)
        variant2 = @variants.last
        variant2.created_at = Date.today - 20.days
        variant2.save
        expect(Spree::Variant.from_created(variant.created_at)).not_to include(variant2)
      end
    end

    describe 'to_created' do
      it 'selects variants with created from the date given upwards' do
        variant2 = @variants.last
        variant2.created_at = Date.today + 20.days
        expect(Spree::Variant.to_created(variant2.created_at)).to include(variant2)
      end
    end
  end

  # def self.derive_sku_components(platform_supplier_sku:)
  #   sku_parts = platform_supplier_sku.split('-')
  #
  #   brand_short_code = sku_parts.pop.strip
  #   original_supplier_sku = sku_parts.join(',')
  #   {
  #       brand_short_code: brand_short_code,
  #       original_supplier_sku: original_supplier_sku,
  #       platform_supplier_sku: platform_supplier_sku
  #   }
  # end

  describe '.derive_sku_components' do
    it 'returns all respective parts properly for SKUs with only supplier segment' do
      platform_supplier_sku = '-XXXYZ'
      results = Spree::Variant.derive_sku_components(platform_supplier_sku: platform_supplier_sku)
      expect(results[:brand_short_code]).to eq('XXXYZ')
      expect(results[:original_supplier_sku]).to be_blank
      expect(results[:platform_supplier_sku]).to eq platform_supplier_sku
    end

    it 'returns all respective parts properly for SKU with only two parts' do
      platform_supplier_sku = 'test-XXXYZ'
      results = Spree::Variant.derive_sku_components(platform_supplier_sku: platform_supplier_sku)
      expect(results[:brand_short_code]).to eq('XXXYZ')
      expect(results[:original_supplier_sku]).to eq 'test'
      expect(results[:platform_supplier_sku]).to eq platform_supplier_sku
    end

    it 'returns all respective parts properly for SKU with only three parts' do
      platform_supplier_sku = 'michael-test-BBBYZ'
      results = Spree::Variant.derive_sku_components(platform_supplier_sku: platform_supplier_sku)
      expect(results[:brand_short_code]).to eq('BBBYZ')
      expect(results[:original_supplier_sku]).to eq 'michael-test'
      expect(results[:platform_supplier_sku]).to eq platform_supplier_sku
    end
  end
end
