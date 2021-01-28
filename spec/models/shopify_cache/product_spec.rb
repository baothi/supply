require 'rails_helper'

RSpec.describe ShopifyCache::Product, type: :model do
  include Mongoid::Matchers

  subject { build(:shopify_cache_product) }

  before do
    Mongoid.purge!
  end

  describe 'Model from Factory' do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to be_dynamic_document }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:shopify_url) }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe 'Fields' do
    it { is_expected.to have_field(:published_at).of_type(String) }
    it { is_expected.to have_field(:updated_at).of_type(String) }
    it { is_expected.to have_field(:shopify_url).of_type(String) }
    it { is_expected.to have_field(:role).of_type(String) }
    it { is_expected.to have_field(:deleted_at).of_type(String) }
  end

  describe 'Indices' do
    it do
      expect(subject).
        to have_index_for(handle: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for(shopify_url: 1, role: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('variants.sku': 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('variants.barcode': 1).
        with_options(background: true)
    end
  end

  describe 'Associations' do
    it { is_expected.to embed_many(:variants).as_inverse_of(:product) }
  end

  describe '.mark_as_deleted!' do
    let!(:products) do
      create_list(:shopify_cache_product,
                  5,
                  shopify_url: spree_supplier.shopify_url,
                  deleted_at: nil)
    end

    it 'marks the correct product for deletion' do
      p = products.first
      ShopifyCache::Product.mark_as_deleted!(supplier: spree_supplier, shopify_identifier: p.id)

      p.reload
      expect(p.deleted_at).not_to be_nil
    end
  end

  describe '#mark_as_deleted!' do
    let!(:product1) do
      create(:shopify_cache_product,
             shopify_url: spree_supplier.shopify_url)
    end

    it 'marks the product as deleted' do
      product1.mark_as_deleted!
      expect(product1.deleted_at).not_to be_nil
    end
  end

  describe '#mark_as_undeleted!' do
    let!(:product1) do
      create(:shopify_cache_product_marked_as_deleted)
    end

    it 'marks the product as deleted' do
      product1.mark_as_undeleted!
      expect(product1.deleted_at).to be_nil
    end
  end

  describe '.locate_variant' do
    let(:product) { create(:shopify_cache_product) }

    before do
      product.variants.first.update(sku: 'FirstRandomSKU-123')
      product.variants.last.update(sku: 'SecondRandomSKU-456')
    end

  end

  describe '.quantity_on_hand' do
    before do
      # Set allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
    end

    context 'when sku is missing' do
      it 'does not raise exception' do
        expect  do
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: nil)
        end.not_to raise_error
      end
      it 'returns zero' do
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: nil)
        ).to eq 0
      end
    end

    context 'when supplier is missing' do
      it 'does not raise exception' do
        expect  do
          ShopifyCache::Product.quantity_on_hand(supplier: nil,
                                                 original_supplier_sku: 'XXX')
        end.not_to raise_error
      end
      it 'returns zero' do
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: nil,
                                                 original_supplier_sku: 'XXX')
        ).to eq 0
      end
    end

    context 'when product is unpublished' do
      let!(:product1) do
        create(:shopify_cache_product,
               shopify_url: spree_supplier.shopify_url,
               published_at: nil)
      end

      it 'returns zero for inventory' do
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0

        sku = product1.variants.first.sku
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku)
        ).to eq 0
      end
      it 'returns the zero for inventory quantity' do
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0

        product = create :shopify_cache_product_with_100_quantity
        sku = product.variants.first.sku
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku)
        ).to eq 0
      end
    end

    context 'when product is published' do
      let!(:product1) do
        create(:shopify_cache_product,
               shopify_url: spree_supplier.shopify_url)
      end

      it 'returns the correct inventory quantity' do
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0

        create(:shopify_cache_product,
               shopify_url: spree_supplier.shopify_url)

        variant = product1.variants.first
        variant.update(inventory_quantity: 5, sku: 'XXXX-2')
        variant.reload
        product1.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXX-2')
        ).to eq variant.inventory_quantity
      end

      it 'returns zero when quantity is below 0' do
        product = create :shopify_cache_product_with_negative_quantity
        sku = product.variants.first.sku
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku)
        ).to eq 0
      end
    end

    context 'when product is deleted' do
      it 'returns the correct inventory quantity' do
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0

        sku_to_use = 'XXXXXXXXX'
        product = create(:shopify_cache_product_marked_as_deleted,
                         shopify_url: spree_supplier.shopify_url)
        variant = product.variants.first
        variant.update(inventory_quantity: 5, sku: sku_to_use)
        variant.reload
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku_to_use)
        ).to eq 0

        product.mark_as_undeleted!
        product.reload

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku_to_use)
        ).to eq variant.inventory_quantity
      end
    end

    context 'when supplier has a buffer set' do
      it 'returns the correct inventory quantity when buffer is set to 0' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        variant = product.variants.first
        variant.update(inventory_quantity: 75, sku: 'XXXXX-1')
        variant.reload
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXXX-1')
        ).to eq variant.inventory_quantity
      end
      it 'returns the correct inventory quantity when buffer is set to 5' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 33
        variant = product.variants.first
        variant.update(inventory_quantity: 39, sku: 'XXXXX')
        variant.reload
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXXX')
        ).to eq 6
      end
    end

    context 'when suppliers variants have inventory_policy ' do
      it 'returns the original number when inventory_policy is set to deny' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        variant = product.variants.first
        variant.update(inventory_quantity: 75, sku: 'XXXXX-2', inventory_policy: 'deny')
        variant.reload
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXXX-2')
        ).to eq variant.inventory_quantity
      end
      it 'returns the the virtual number when inventory_policy is set to continue' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 33
        variant = product.variants.first
        variant.update(inventory_quantity: 100,
                       sku: 'XXXXX-3',
                       inventory_policy: 'continue')
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXXX-3')
        ).to eq 1000
      end

      it 'returns the virtual number when inventory_management is set to nil' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        # allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        variant = product.variants.first
        variant.update(inventory_quantity: 75,
                       sku: 'XXXXX-2',
                       inventory_policy: 'deny',
                       inventory_management: nil)
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'XXXXX-2')
        ).to eq 1000
      end
    end

    context 'when it comes to case sensitivity' do
      it 'can deal with mixed cases properly' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        variant = product.variants.first
        sku = 'XXXXX-1'
        variant.update(inventory_quantity: 75, sku: sku)
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: sku.alternate_case)
        ).to eq variant.inventory_quantity
      end
    end

    context 'when it comes to exact match search' do
      it 'only searches the record for exactly matched sku' do
        product = build(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        variant = product.variants.first
        sku = 'COMPLETESKU'
        variant.update(inventory_quantity: 75, sku: sku)
        product.save

        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'COMPLETESKU')
        ).to eq variant.inventory_quantity
      end

      it 'does not bring back the records for not exact sku match' do
        product = create(:shopify_cache_product,
                         shopify_url: spree_supplier.shopify_url)
        allow(spree_supplier).to receive(:setting_inventory_buffer).and_return 0
        variant = product.variants.first
        sku = 'COMPLETESKU'
        variant.update(inventory_quantity: 75, sku: sku)
        product.save

        expect(
          ShopifyCache::Product.quantity_on_hand(supplier: spree_supplier,
                                                 original_supplier_sku: 'COMPLETES')
        ).to eq 0
      end
    end
  end
end
