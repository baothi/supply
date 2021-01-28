require 'rails_helper'

RSpec.describe Shopify::AddTaxonProductsJob, type: :job do
  include ActiveJob::TestHelper

  let!(:taxon) do
    create(:taxon, products: create_list(:spree_product, 3))
  end

  let!(:long_job) do
    create(:spree_long_running_job,
           action_type: 'export',
           job_type: 'products_export',
           initiated_by: 'user',
           retailer_id: spree_retailer.id,
           option_1: taxon.id,
           option_2: 'add_taxon_products_to_shopify')
  end

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform_later' do
    it 'adds the job to the :shopify_export' do
      expect do
        described_class.perform_later(long_job.internal_identifier)
      end.to enqueue_job(described_class).
        with(long_job.internal_identifier).
        on_queue('shopify_export')
    end
  end

  describe '#perform' do
    it 'calls on the ShopifyMailer' do
      allow_any_instance_of(Shopify::Product::BulkExporter).to receive(:perform).
        and_return('All new products have been added to your shopify store')

      allow(ShopifyMailer).to receive(:add_taxon_products_to_shopify).
        with('All new products have been added to your shopify store', spree_retailer)

      described_class.new.perform(long_job.internal_identifier)

      expect(ShopifyMailer).to have_received(:add_taxon_products_to_shopify)
    end

    context 'when there is an existing job with complete or error status' do
      before do
        expect_any_instance_of(Spree::LongRunningJob).to receive(:initialize_and_begin_job!).at_least(:once)
      end

      it 'enqueues a new job if the previous job was completed' do
        long_job.complete_job!

        described_class.new.perform(long_job.internal_identifier)
      end

      it 'enqueues a new job if the previous job failed' do
        long_job.update(status: :error)

        described_class.new.perform(long_job.internal_identifier)
      end
    end
  end
end
