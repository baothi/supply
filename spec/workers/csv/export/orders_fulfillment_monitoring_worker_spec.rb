require 'rails_helper'

RSpec.describe Csv::Export::OrdersFulfillmentMonitoringWorker, type: :worker do
  let(:supplier) { create(:spree_supplier) }
  let(:retailer) { create(:spree_retailer) }

  let(:job) do
    create(:spree_long_running_job,
           hash_option_1: {
               from_date: Date.today - 1.year,
               to_date: Date.today + 1.day
           },
           retailer_id: retailer.id)
  end

  let(:subject) { described_class.new }

  let(:shopify_orders) do
    create_list(:shopify_cache_order,
                2,
                fulfillment_status: 'unfulfilled',
                shopify_url: supplier.shopify_url)
  end

  let(:order1) do
    create(:spree_order_with_line_items,
           retailer: retailer,
           supplier_shopify_identifier: shopify_orders.first.id,
           shipment_state: 'pending')
  end
  let(:order2) do
    create(:spree_order_with_line_items,
           retailer: retailer,
           supplier_shopify_identifier: shopify_orders.last.id,
           shipment_state: 'shipped')
  end

  describe 'perform' do
    before do
      order1.reload
      order2.reload
    end

    after do
      shopify_orders.each(&:remove)
    end

    it 'generates orders fulfillment report successfully' do
      subject.perform(job.internal_identifier)

      expect(job).not_to be_in_progress
      expect(job.error_log).to be_nil
    end
  end
end
