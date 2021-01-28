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

  describe 'Adding referrals', brand: true do
    brand_name = Faker::Company.name
    brand_url = Faker::Internet.url

    it 'submits the referral form successfully' do
      visit supplier_add_referral_path
      expect(page).to have_content 'Thank you for signing up as a supplier!'
      expect(page).to have_content 'Invite your current or ideal partners'

      fill_in_referral_form brand_name, brand_url

      assert_new_referral_created brand_name, brand_url
    end

    it 'does not allow user entering the same url again' do
      visit supplier_add_referral_path

      fill_in_referral_form brand_name, brand_url
      expect(current_path).to eql(supplier_referrals_path)

      visit supplier_add_referral_path
      fill_in_referral_form brand_name, brand_url

      expect(find('#error_explanation')).to have_content 'Url already exists in your invites.'
    end

    it 'shows error when submitting invalid url' do
      visit supplier_add_referral_path

      fill_in_referral_form brand_name, 'sftp:/invalid-url'

      expect(find('#error_explanation')).to have_content 'Url is not a valid HTTP URL'
    end
  end

  def fill_in_referral_form(name, url)
    within '.referral-form' do
      fill_in 'retailer_referral[name]', with: name
      fill_in 'retailer_referral[url]', with: url

      check 'inputCheckbox'
      click_button 'ADD'
    end
  end

  def assert_new_referral_created(name, url)
    expect(current_path).to eql(supplier_referrals_path)
    expect(find('.referral-list')).to have_content "#{name} (#{url})"
  end
end
