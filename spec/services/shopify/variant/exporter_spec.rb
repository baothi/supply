require 'rails_helper'

RSpec.describe Shopify::Variant::Exporter, type: :service do
  before do
    allow(ShopifyAPI::Product).to receive(:find).and_return @shopify_product
    allow(ShopifyAPI::Product).to receive(:delete).and_return true
    allow(ShopifyAPI::Variant).to receive(:delete).and_return true
    allow(ShopifyAPI::Variant).to receive(:count).and_return 1
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    @retailer = spree_retailer
    @supplier = spree_supplier
    @variant = load_fixture('shopify/variant')
    @shopify_product = load_fixture('shopify/product')
  end

  let(:subject) do
    Shopify::Variant::Exporter.new(
      retailer: @retailer,
      shopify_product: @shopify_product,
      local_product: product
    )
  end
  let(:variant) { create(:spree_variant_with_quantity) }
  let(:product) { create(:spree_product) }

  describe '#perform' do
    it 'exports images for variants' do
      expect(subject).to receive(:export_variant_image).
        exactly(@shopify_product.variants.count).times
      subject.perform
    end

    it 'sets inventory for shopify variants' do
      expect(subject).to receive(:set_inventory).exactly(@shopify_product.variants.count).times
      subject.perform
    end
  end
end
