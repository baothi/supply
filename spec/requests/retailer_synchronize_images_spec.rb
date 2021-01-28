require 'rails_helper'

RSpec.describe 'Retailer Synchronize Images', type: :request do
  before do
    ActiveJob::Base.queue_adapter = :test
    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  describe 'GET /retailer/products/:product_id/sync_images' do
    it 'enqeues job to sync images' do
      @product = create(:spree_product_in_stock)
      create(
        :spree_product_listing,
        product: @product,
        retailer: spree_retailer,
        supplier: spree_supplier
      )

      expect(Shopify::SyncImagesJob).to receive(:perform_later)

      get "http://localhost:3000/retailer/products/#{@product.internal_identifier}/sync_images"
    end
  end
end
