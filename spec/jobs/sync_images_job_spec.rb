require 'rails_helper'

RSpec.describe Shopify::SyncImagesJob, type: :job do
  include ActiveJob::TestHelper
  let (:job) { Shopify::SyncImagesJob.new }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  before :all do
    @shopify_product = load_fixture('shopify/product')
  end

  let(:listing) do
    create(
      :spree_product_listing,
      retailer: spree_retailer,
      supplier: spree_supplier
    )
  end
  let(:long_job) do
    create(:spree_long_running_job, supplier: @supplier, option_1: listing.internal_identifier)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Spree::Retailer).to receive(:init).and_return(true)
    end

    it 'looks for product in shopify' do
      expect(CommerceEngine::Shopify::Product).to receive(:find).with(listing.shopify_identifier)
      job.perform(long_job.internal_identifier)
    end

    it 'exports product images' do
      allow(CommerceEngine::Shopify::Product).to receive(:find).with(listing.shopify_identifier).
        and_return(@shopify_product)
      expect(job).to receive(:export_product_images)
      job.perform(long_job.internal_identifier)
    end

    it 'exports variants images' do
      vl = build(:spree_variant_listing, product_listing: listing)
      allow(CommerceEngine::Shopify::Product).to receive(:find).with(listing.shopify_identifier).
        and_return(@shopify_product)
      allow(job).to receive(:export_product_images).and_return true
      allow(Spree::VariantListing).to receive(:find_by).and_return(vl)

      expect(job).to receive(:export_variant_image).exactly(@shopify_product.variants.count).times
      job.perform(long_job.internal_identifier)
    end
  end
end
