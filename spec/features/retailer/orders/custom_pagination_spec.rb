require 'rails_helper'

RSpec.describe 'Custom Pagination', type: :request do
  before do
    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  before do
    create_list(:spree_completed_order_with_totals, 5, retailer: spree_retailer)
  end

  describe 'GET /retailer/orders' do
    context 'when per page is passed' do
      it 'sets and stores per page attribute' do
        get 'http://localhost:3000/retailer/orders?per_page=25'

        expect(session[:per_page]).to eq '25'
        expect(assigns(:per_page)).to eq '25'
      end
    end

    context 'when per page is not passed and session per page is empty' do
      it 'defaults per_page to 10' do
        get 'http://localhost:3000/retailer/orders'

        expect(assigns(:per_page)).to eq '10'
      end
    end

    context 'when per page is not passed and session per page is present' do
      before do
        get 'http://localhost:3000/retailer/orders?per_page=50'
      end

      it 'sets per_page to session[:per_page] value' do
        get 'http://localhost:3000/retailer/orders'

        expect(assigns(:per_page)).to eq '50'
      end
    end

    context 'when a value above 100 is manually passed for per_page' do
      it 'resets per_page to 100' do
        get 'http://localhost:3000/retailer/orders?per_page=200'

        expect(session[:per_page]).to eq '100'
      end
    end
  end
end
