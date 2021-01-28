require 'rails_helper'

RSpec.describe 'Selling Authority', type: :feature do
  include Warden::Test::Helpers
  Warden.test_mode!
  before do
    admin = create(:supply_admin_user)
    login_as(admin, scope: :admin_user)
  end

  xit 'visits the appropriate page' do
    visit '/active/admin/spree_selling_authorities'

    expect(page).to have_content('Spree Selling Authorities')
  end

  describe 'filtering' do
    let(:retailer_one) { create(:spree_retailer) }
    let(:retailer_two) { create(:spree_retailer) }
    let!(:selling_authority_one) { create(:spree_selling_authority, retailer: retailer_one) }
    let!(:selling_authority_two) { create(:spree_selling_authority, retailer: retailer_two) }

    before { visit '/active/admin/spree_selling_authorities' }

    context 'by retailer' do
      xit 'displays only retailer selling authorities' do
        within('.index_as_table') do
          expect(page).to have_content(retailer_one.name)
          expect(page).to have_content(retailer_two.name)
        end

        select(retailer_one.name, from: 'q[retailer_id_eq]')
        find('#q_retailer_id').select(retailer_one.name)
        click_button('Filter')

        within('.index_as_table') do
          expect(page).not_to have_content(retailer_two.name)
        end

      end
    end
  end
end
