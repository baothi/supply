require 'rails_helper'

RSpec.describe Shopify::Product::BulkInventoryUpdater, type: :service do
  before do
    ActiveJob::Base.queue_adapter = :test
    @inventory_levels = double(load_fixture('shopify/inventory_levels').inventory_levels)
    @inventory_adjustments = load_fixture('shopify/graph_ql/inventory_levels_adjustments')

    allow_any_instance_of(Spree::Retailer).to receive(:initialize_shopify_session!).and_return true
    allow_any_instance_of(Spree::Retailer).to receive(:destroy_shopify_session!).and_return true
  end

  let(:retailer) { create(:spree_retailer, default_location_shopify_identifier: '12345') }
  let(:supplier) { create(:spree_supplier) }
  let(:credential) { create(:spree_shopify_credential, teamable: retailer) }

  let(:variants) { create_list(:spree_variant, 2) }
  let(:variant_listing_1) do
    create(:spree_variant_listing,
           variant: variants.first,
           retailer: retailer,
           supplier_id: supplier.id,
           shopify_identifier: '444555')
  end
  let(:variant_listing_2) do
    create(:spree_variant_listing,
           variant: variants.last,
           retailer: retailer,
           supplier_id: supplier.id,
           shopify_identifier: '666777')
  end

  let(:subject) do
    described_class.new(retailer_id: retailer.id)
  end

  describe '#perform' do
    before do
      variant_listing_1.reload
      variant_listing_2.reload

      allow(retailer).to receive(:shopify_credential).and_return credential
      allow(ShopifyAPI::InventoryLevel).to receive(:find).and_return(
        @inventory_levels
      )
      allow(@inventory_levels).to receive(:next_page?).and_return(true, false)
      allow(@inventory_levels).to receive(:fetch_next_page).and_return(
        @inventory_levels
      )
      allow(subject).to receive(:process_inventory_levels).and_return(true)
      allow_any_instance_of(Shopify::GraphAPI::InventoryLevel).
        to receive(:update).and_return @inventory_adjustments
    end

    it 'updates retailer inventory quantities in bulk successfully' do
      ro = subject.perform
      expect(ro.message).to eq 'N/A'
      expect(ro.success).to be_truthy
    end
  end
end
