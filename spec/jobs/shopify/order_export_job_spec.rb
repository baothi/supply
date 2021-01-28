require 'rails_helper'

RSpec.describe Shopify::OrderExportJob, type: :job do
  include ActiveJob::TestHelper

  # let!(:long_job) do
  #   create(:spree_long_running_job,
  #          action_type: 'export',
  #          job_type: 'products_export',
  #          initiated_by: 'user',
  #          retailer_id: spree_retailer.id,
  #          option_1: taxon.id,
  #          option_2: 'add_taxon_products_to_shopify')
  # end

  before do
    ActiveJob::Base.queue_adapter = :test
    Mongoid.purge!
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#check_quantities' do
    let!(:spree_order) do
      create(:spree_order_ready_to_ship, shopify_processing_status: 'cost_check')
    end

    let(:published_shopify_cache_product) do
      create(:shopify_cache_product,
             published_at: DateTime.now,
             shopify_url: spree_supplier.shopify_url)
    end

    let(:unpublished_shopify_cache_product) do
      create(:shopify_cache_product,
             published_at: nil,
             shopify_url: spree_supplier.shopify_url)
    end

    let(:shopify_cache_variant) do
      build(:shopify_cache_variant)
    end

    before do
      allow_any_instance_of(described_class).
        to receive(:check_for_line_item_replacement_candidacy_and_execute).and_return(true)
      allow_any_instance_of(Spree::Order).
        to receive(:shopify_order?).and_return(true)
    end

    it 'raises an error when there is no quantity' do
      allow(Spree::Variant).to receive(:available_quantity).and_return(0)
      allow(ShopifyCache::Variant).
        to receive(:locate_at_supplier).and_return(
          [shopify_cache_variant, published_shopify_cache_product]
        )

      described_class.new.check_quantities(spree_order)
      expect(spree_order.shopify_logs).to include('in stock')
    end

    it 'raises an error when there item is unpublished' do
      allow(Spree::Variant).to receive(:available_quantity).and_return(100)
      allow(ShopifyCache::Variant).to receive(:locate_at_supplier).and_return(
        [shopify_cache_variant, unpublished_shopify_cache_product]
      )
      described_class.new.check_quantities(spree_order)
      expect(spree_order.shopify_logs).to include('is no longer available for')
    end

    it 'executes all the way through' do
      allow(Spree::Variant).to receive(:available_quantity).and_return(200)
      allow(ShopifyCache::Variant).
        to receive(:locate_at_supplier).and_return(
          [shopify_cache_variant, published_shopify_cache_product]
        )

      expect(described_class.new.check_quantities(spree_order)).to be_truthy
      expect(spree_order.shopify_logs).to be_nil
    end
  end
end
