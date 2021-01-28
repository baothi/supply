require 'rails_helper'

RSpec.describe 'Retailer - Shopify Controller', type: :request do
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'GET /retailer/shopify/fetch_stock.json' do
    it 'does work for retailers' do
      get 'http://localhost:3000/retailer/shopify/fetch_stock.json', nil, nil
      expect(response).to be_success
      expect(JSON.parse(response.body)).to eq ({})
    end
  end
end
