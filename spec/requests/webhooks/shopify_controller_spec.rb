require 'rails_helper'

RSpec.describe 'Shopify Webhooks', type: :request do
  let(:shopify_cache_order) do
    create(:shopify_cache_order)
  end

  let(:shopify_webhook_supplier_path) do
    'http://localhost:3000/webhooks/shopify/supplier'
  end

  let(:shopify_webhook_retailer_path) do
    'http://localhost:3000/webhooks/shopify/retailer'
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    Mongoid.purge!
    # We return a JSON object for the controllers to reparse
    allow_any_instance_of(Webhooks::ShopifyController).to(
      receive(:data_object).and_return(shopify_cache_order.to_json)
    )
  end

  describe 'GET /webhooks/shopify/:teamable_type/:team_identifier' do
    context 'order_import' do
      it 'raises errors for suppliers' do
        expect do
          post "#{shopify_webhook_supplier_path}/#{spree_supplier.internal_identifier}/",
               params: {},
               headers: shopify_orders_created_header
        end.to raise_error(/This endpoint is/)
      end

      it 'does work for retailers' do
        post "#{shopify_webhook_retailer_path}/#{spree_retailer.internal_identifier}/",
             params: {},
             headers: shopify_orders_created_header
        expect(response).to be_success
      end

      it 'enqueues the order import job' do
        expect(ShopifyOrderImportJob).to receive(:perform_later)

        post "#{shopify_webhook_retailer_path}/#{spree_retailer.internal_identifier}/",
             params: {},
             headers: shopify_orders_created_header

        expect(response).to be_success
      end
    end
  end
end
