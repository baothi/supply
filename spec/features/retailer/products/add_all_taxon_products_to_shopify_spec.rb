require 'rails_helper'

RSpec.describe 'Add all taxon products to shopify', type: :feature do
  let(:retailer) { spree_retailer }
  let(:current_user) { retailer.users.first }

  before do
    category_taxonomy = create(:taxonomy, name: 'Category')
    @taxon = create(:taxon, taxonomy: category_taxonomy)
  end

  xit 'When the current user is a spree_user' do
    login_as(current_user)
    visit retailer_list_products_by_category_path(category: @taxon.name)

    expect(page).not_to have_button('Add All Products to Shopify')
  end

  xit 'When the current user is a hingeto_user' do
    current_user.update(email: 'test@hingeto.com')
    login_as(current_user)
    visit retailer_list_products_by_category_path(category: @taxon.name)

    expect(page).to have_button('Add All Products to Shopify')
  end
end
