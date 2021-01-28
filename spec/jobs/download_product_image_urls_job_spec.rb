require 'rails_helper'

RSpec.describe Shopify::DownloadProductImageUrlsJob, type: :job do
  include ActiveJob::TestHelper
  let (:subject) { Shopify::DownloadProductImageUrlsJob.new }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  before :all do
    @shopify_product = load_fixture('shopify/product')
  end

  let(:product) { create(:spree_product_in_stock, image_urls: [Faker::Internet.url]) }

  let(:long_job) do
    create(:spree_long_running_job, supplier: @supplier, option_1: product.internal_identifier)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Spree::Supplier).to receive(:init).and_return(true)
    end

    xit 'looks for product in shopify' do
      expect(CommerceEngine::Shopify::Product).to receive(:find).with(product.shopify_identifier)
      subject.perform(long_job.internal_identifier)
    end

    xit 'attaches all images' do
      allow(CommerceEngine::Shopify::Product).to receive(:find).with(product.shopify_identifier).
        and_return(@shopify_product)
      expect(subject).to receive(:attach_all_images)
      subject.perform(long_job.internal_identifier)
    end

    xit 'enqueues. image import job' do
      allow(CommerceEngine::Shopify::Product).to receive(:find).with(product.shopify_identifier).
        and_return(@shopify_product)
      allow(subject).to receive(:attach_all_images).and_return true
      expect do
        subject.perform(long_job.internal_identifier)
      end.to have_enqueued_job(Shopify::ImportProductImageJob)
    end
  end

  describe '#remove_previous_local_images' do
    it 'removes existing image urls' do
      expect(product.image_urls).not_to eq []
      subject.remove_previous_local_images(product)

      expect(product.reload.image_urls).to eq []
    end
  end

  describe '#attach_image' do
    xit 'removes existing image urls' do
      url = Faker::Internet.url
      subject.attach_image(product.shopify_identifier, url, 'Spree::Product')

      expect(product.reload.image_urls).to include url
    end
  end
end
