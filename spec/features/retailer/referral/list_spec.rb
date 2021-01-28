require 'rails_helper'

RSpec.describe 'Retailer Referral', type: :feature do
  let!(:retailer) do
    create :spree_retailer_without_access_granted
  end

  let!(:current_user) do
    retailer.users.first
  end

  before do
    login_as(current_user, scope: :spree_user)
  end

  describe 'Clicking the plus button' do
    it 'redirects to the add page' do
      visit retailer_referrals_path
      find('#add_referral_link').click
      expect(current_path).to eql(retailer_add_referral_path)
    end
  end
end
