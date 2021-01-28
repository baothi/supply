RSpec.shared_examples 'an internal_skuable model' do
  describe '#before_validate' do
    it 'generates an internal_identifier before saving'  do
      subject.internal_sku_suffix = nil
      subject.internal_sku = nil
      subject.save!
      expect(subject).to be_valid
      expect(subject.internal_sku_suffix).not_to be_nil
      expect(subject.internal_sku).not_to be_nil
    end
  end

  describe '#generate_product_internal_sku_base' do
    it 'generates an internal_sku_base for products' do
      subject.internal_sku_suffix = nil
      subject.internal_sku = nil
      subject.save
      product = subject.product
      expect(subject).to be_valid
      expect(subject.internal_sku_suffix).not_to be_nil
      expect(subject.internal_sku).not_to be_nil
      expect(product.internal_sku_base).not_to be_nil
    end
  end

  describe '#replace_sku_with_internal_sku!' do
    it 'copies over old sku to supplier sku' do
      subject.internal_sku_suffix = nil
      subject.internal_sku = nil
      subject.platform_supplier_sku = nil
      subject.sku = 'OLD_SKU'
      subject.save

      subject.replace_sku_with_internal_sku!

      expect(subject).to be_valid
      expect(subject.platform_supplier_sku).not_to be_nil
      expect(subject.platform_supplier_sku).to eq 'OLD_SKU'
      expect(subject.sku).to start_with 'HT-'
    end
  end

  describe 'scopes' do
    context 'uses_legacy_sku_mechanism' do
      it 'identifies valid legacy skus correctly' do
        subject.sku = 'XXXX-XXXX'
        subject.save
        expect(Spree::Variant.uses_legacy_sku_mechanism.all).to include subject
      end

      it 'identifies invalid legacy skus correctly' do
        subject.sku = 'HT-XXXX-XXXX'
        subject.save
        expect(Spree::Variant.uses_legacy_sku_mechanism.all).not_to include subject
      end
    end
  end
end
