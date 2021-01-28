require 'rails_helper'

RSpec.describe 'Reported Order', type: :request do
  let(:supplier) { spree_supplier }
  let(:order) { create(:spree_order_ready_to_ship, supplier: supplier) }
  let(:subject) do
    get "http://localhost:3000/supplier/orders/import-fulfillment/#{order.internal_identifier}"
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    sign_in(spree_supplier.users.first)
  end

  describe 'GET /supplier/orders/import-fulfillment/:order_id' do
    it 'queues import fulfillment job' do
      expect { subject }.to have_enqueued_job(ShopifyFulfillmentImportJob)
    end
  end
end
