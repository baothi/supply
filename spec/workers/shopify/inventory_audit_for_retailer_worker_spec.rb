require 'rails_helper'

RSpec.describe Shopify::InventoryAuditForRetailerWorker, type: :worker do
  let(:supplier) { create(:spree_supplier) }
  let(:retailer) { create(:spree_retailer) }

  let(:job) { create(:spree_long_running_job, retailer: retailer) }
  let(:subject) { described_class.new }

  let(:variant_listings) do
    create_list(:spree_variant_listing, 2, retailer: retailer, supplier_id: supplier.id)
  end
  let(:skus) { variant_listings.map(&:variant).map(&:platform_supplier_sku) }
  let(:shopify_product) do
    create(:shopify_cache_product,
           shopify_url: retailer.shopify_url,
           role: 'retailer',
           variants: [
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: skus[0]
               ),
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: skus[1]
               )
           ])
  end

  let(:shopify_supplier_product) do
    create(:shopify_cache_product,
           shopify_url: supplier.shopify_url,
           role: 'supplier',
           variants: [
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: skus[0]
               ),
               FactoryBot.build(
                 :shopify_cache_product_variant,
                 sku: skus[1]
               )
           ])
  end

  describe 'perform' do
    before do
      allow_any_instance_of(Spree::Retailer).
        to receive(:shopify_retailer?).and_return(true)
      allow_any_instance_of(Spree::Supplier).
        to receive(:shopify_supplier?).and_return(true)
      allow(subject).to receive(:email_audit_file).and_return(true)

      shopify_product.reload
      shopify_supplier_product.reload
    end

    it 'generates inventory audit report for retailer', heals: true do
      expect(job).not_to be_in_progress

      subject.perform(job.internal_identifier)

      expect(job).not_to be_in_progress
      expect(job.error_log).to be_nil
    end
  end
end
