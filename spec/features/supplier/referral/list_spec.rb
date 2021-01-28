require 'rails_helper'

RSpec.describe 'Supplier Referral', type: :feature do
  let!(:supplier) do
    create :spree_supplier_without_access_granted
  end

  let!(:current_user) do
    supplier.users.first
  end

  before do
    login_as(current_user, scope: :spree_user)
  end

  describe 'Clicking the plus button' do
    it 'redirects to the add page' do
      visit supplier_referrals_path
      find('#add_referral_link').click
      expect(current_path).to eql(supplier_add_referral_path)
    end
  end
end
