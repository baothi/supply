require 'rails_helper'

RSpec.describe Shopify::FulfillmentService::FetchStock, type: :service do
  subject { Shopify::FulfillmentService::FetchStock.new(shop: retailer.shopify_url) }

  before { ActiveJob::Base.queue_adapter = :test }

  before { retailer.update(shopify_url: 'hingeto-fake@myshopify.com') }

  let (:retailer) { spree_retailer }

  describe '#initialize' do
    context 'when shop is missing' do
      subject { Shopify::FulfillmentService::FetchStock.new }

      it 'raises error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'when shop is present' do
      it 'sets retailer' do
        expect(subject.retailer).to eq retailer
      end
    end
  end

  describe '#perform' do
    let(:variant_listings) do
      create_list(:spree_variant_listing, 2, retailer: retailer, supplier_id: spree_supplier.id)
    end

    context 'when sku is present' do
      let(:variant) { variant_listings.first.variant }
      let(:sku) { variant.platform_supplier_sku }

      context 'when sku exists' do
        subject do
          Shopify::FulfillmentService::FetchStock.new(shop: retailer.shopify_url, sku: sku)
        end

        it 'returns hash of sku and inventory' do
          expect(subject.perform).to eq(sku => variant.count_on_hand)
        end
      end

      context 'when sku does not exist' do
        subject  do
          Shopify::FulfillmentService::FetchStock.new(shop: retailer.shopify_url, sku: 'random')
        end

        it 'raises error' do
          expect { subject.perform }.not_to raise_error(RuntimeError)
        end
      end
    end

    context 'when sku is not present' do
      subject  { Shopify::FulfillmentService::FetchStock.new(shop: retailer.shopify_url) }

      let(:shopify_product) do
        create(:shopify_cache_product,
               shopify_url: retailer.shopify_url,
               role: 'retailer',
               variants: [
                   FactoryBot.build(
                     :shopify_cache_product_variant,
                     sku: variant_listings.first.variant.platform_supplier_sku
                   ),
                   FactoryBot.build(
                     :shopify_cache_product_variant,
                     sku: variant_listings.last.variant.platform_supplier_sku
                   )
               ])
      end

      it 'returns hash inventory of all retailer variant listings' do
        shopify_product.reload
        skus = variant_listings.map(&:variant).map(&:platform_supplier_sku)
        retailer.generate_inventories!
        # inventories = variant_listings.map(&:variant).map(&:count_on_hand)
        subject.perform
        expect(subject.perform.keys).to match_array(skus)
        # expect(subject.perform.values).to match_array(inventories)
      end
    end
  end
end
