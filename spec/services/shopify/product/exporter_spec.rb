require 'rails_helper'

RSpec.describe Shopify::Product::Exporter, type: :service do
  before do
    ActiveJob::Base.queue_adapter = :test
    @retailer = spree_retailer
    @supplier = spree_supplier
    @shopify_product = load_fixture('shopify/graph_ql/product')
    allow(subject).to receive(:local_product).and_return(product)
    allow(subject).to receive(:export_process).and_return(export_process)

    allow(@retailer).to receive(:shopify_credential).and_return credential
    allow_any_instance_of(Shopify::GraphAPI::Product).
      to receive(:create).and_return @shopify_product
  end

  let (:subject) do
    Shopify::Product::Exporter.new(
      retailer_id: @retailer.id
    )
  end

  let(:product) { create(:spree_product_in_stock) }
  let(:export_process) { create(:spree_product_export_process) }

  let(:product_listing) do
    create :spree_product_listing,
           retailer_id: @retailer.id,
           supplier_id: @supplier.id,
           product_id: product.id
  end
  let(:variant) { create(:spree_variant, product: product, platform_supplier_sku: 'TSY00-XCUXW') }

  let(:engine) { CommerceEngine::Shopify::Product }

  let(:credential) { create(:spree_shopify_credential, teamable: @retailer) }

  describe '#set_export_process' do
    it 'begins export process' do
      allow(Spree::ProductExportProcess).to receive(:find_by).and_return(export_process)
      expect(export_process).to receive(:begin_export!)
      subject.set_export_process
    end
  end

  describe '#log_error_to_export_process' do
    let!(:log) { Faker::Lorem.sentence }

    context 'when no export process' do
      it 'returns nil' do
        allow(subject).to receive(:export_process).and_return(nil)
        expect(subject.log_error_to_export_process(log)).to eq nil
      end
    end

    context 'when export process exists' do
      it 'raises export process issue' do
        allow(subject).to receive(:export_process).and_return(export_process)
        expect(export_process).to receive(:raise_issue!)
        subject.log_error_to_export_process(log)
      end

      it 'logs error' do
        allow(subject).to receive(:export_process).and_return(export_process)
        subject.log_error_to_export_process(log)
        expect(export_process.reload.error_log).to include(log)
      end
    end
  end

  describe '#perform' do
    before do
      allow(engine).to receive(:create).and_return @shopify_product
      allow(export_process).to receive(:complete_export!).and_return true
    end

    it 'sets export process' do
      expect(subject).to receive(:set_export_process)
      subject.perform(product.internal_identifier)
    end

    it 'creates a new listing' do
      allow(product.variants).to receive(:find_by).and_return variant
      subject.perform(product.internal_identifier)

      product_listing = product.retailer_listing(@retailer.id)
      expect(product_listing.shopify_identifier).to eq('12345678999')
    end

    context 'when listing for product exists and product is on shopify' do
      before do
        allow(product).to receive(:retailer_listing).and_return product_listing
      end

      it 'returns true' do
        expect(subject.perform(product.internal_identifier)).to eq true
      end

      it 'does not create a new shopify product' do
        expect(ShopifyAPI::Product).not_to receive(:new)
        subject.perform(product.internal_identifier)
      end
    end
  end
end
