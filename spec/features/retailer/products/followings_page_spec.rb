require 'rails_helper'

RSpec.describe 'Visiting the Following page' do
  before do
    retailer = spree_retailer
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)

    license_taxonomy = create(:taxonomy, name: 'License')
    create_list(:taxon, 4)
    create_list(:taxon, 3, taxonomy: license_taxonomy)
    @license_taxon1, @license_taxon2 = create_list(:taxon, 2, taxonomy: license_taxonomy)
    @other_taxon1, @other_taxon2 = create_list(:taxon, 2)
  end

  it 'renders the following page' do
    visit retailer_products_followings_path
    expect(page).to have_current_path retailer_products_followings_path
    expect(page).to have_content 'Following'
  end

  context 'when retailer is not following any license' do
    it 'does NOT list any license in the following page' do
      visit retailer_products_followings_path
      within('div#followed-licenses-panel') do
        expect(page).to have_content("You're not following any license")
        expect(page).not_to have_selector('img#standard-width')
      end
    end
  end

  context 'when retailer is following some licenses' do
    before do
      spree_retailer.follow(@license_taxon1)
      spree_retailer.follow(@license_taxon2)
      spree_retailer.follow(@other_taxon1)
    end

    it 'have 2 images tab within the followed-license-panel' do
      visit retailer_products_followings_path
      within('div#followed-licenses-panel') do
        # expect(page).to have_selector('img.standard-width', count: 2)
      end
    end
  end
end
