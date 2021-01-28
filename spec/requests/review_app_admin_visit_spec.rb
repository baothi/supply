require 'rails_helper'

RSpec.describe 'Visiting the admin page', type: :request do
  before do
    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  context 'when visiting the active admin page' do
    it 'checks whether a review app' do
      expect(Supply::ReviewApp::Helpers).to receive(:review_app?).at_least(:once)
      get '/active/admin'
    end

    describe 'admin_user_from_regular_user!' do
      context 'when a review app' do
        before do
          allow(Supply::ReviewApp::Helpers).to receive(:review_app?).and_return(true)
          allow_any_instance_of(Spree::User).to receive(:hingeto_user?).and_return(true)
        end

        it 'AdminUser receives find_or_create_by' do
          expect(AdminUser).to receive(:find_or_create_by) { Spree::User.first }
          get '/active/admin'
        end

        it 'creates AdminUser' do
          expect { get '/active/admin' }.to change(AdminUser, :count).by(1)
        end
      end

      context 'when NOT a review app' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:review_app?).and_return(false)
          allow_any_instance_of(Spree::User).to receive(:hingeto_user?).and_return(true)
        end

        it 'does NOT receive find_or_create_by' do
          expect(AdminUser).not_to receive(:find_or_create_by)
          get '/active/admin'
        end

        it 'does NOT creates AdminUser' do
          expect { get '/active/admin' }.not_to change(AdminUser, :count)
        end
      end
    end
  end
end
