require 'rails_helper'

RSpec.describe 'Retailer Setting', type: :request do
  before do
    # @supplier = create(:spree_supplier)
    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  describe 'GET /retailer/settings/addresses' do
    it 'renders the index view' do
      get 'http://localhost:3000/retailer/settings/addresses'
      expect(response).to render_template(:index)
    end
  end

  describe 'PATCH /retailer/settings/addresses/update-address/legal_entity_address' do
    before do
      @address_attr = attributes_for(
        :spree_address,
        first_name: nil,
        last_name: nil,
        phone: nil
      )
    end

    context 'when all parameter is passed' do
      it 'updates the business address of the current retailer' do
        patch 'http://localhost:3000/retailer/settings/addresses/update-address/legal_entity_address',
              params: {
                retailer: {
                  legal_entity_address_attributes: @address_attr
                }
              }

        expect(flash[:notice]).to include 'updated successfully'
        expect(response).to redirect_to retailer_addresses_path
      end
    end

    context 'when the address1 is NOT filled' do
      before do
        @address_attr['address1'] = nil
      end

      it 'does NOT updates the business address of the current retailer' do
        patch 'http://localhost:3000/retailer/settings/addresses/update-address/legal_entity_address',
              params: {
                retailer: {
                  legal_entity_address_attributes: @address_attr
                }
              }
        # binding.pry
        expect(response).to render_template :index
        expect(response.body).to include 'Unable to update address'
      end
    end
  end

  describe 'PATCH /retailer/settings/addresses/update-address/shipping_address' do
    before do
      @address_attr = attributes_for(
        :spree_address,
        first_name: nil,
        last_name: nil,
        phone: nil
      )
    end

    context 'when all parameter is passed' do
      it 'updates the business address of the current retailer' do
        patch 'http://localhost:3000/retailer/settings/addresses/update-address/shipping_address',
              params: {
                retailer: {
                  shipping_address_attributes: @address_attr
                }
              }

        expect(flash[:notice]).to include 'updated successfully'
        expect(response).to redirect_to retailer_addresses_path
      end
    end

    context 'when the address1 is NOT filled' do
      before do
        @address_attr['address1'] = nil
      end

      it 'does NOT updates the business address of the current retailer' do
        patch 'http://localhost:3000/retailer/settings/addresses/update-address/shipping_address',
              params: {
                retailer: {
                  shipping_address_attributes: @address_attr
                }
              }

        # expect(flash[:alert]).to include 'Unable to update address'
        expect(response).to render_template :index
        expect(response.body).to include 'Unable to update address'
      end
    end
  end
end
