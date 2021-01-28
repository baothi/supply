require 'rails_helper'

RSpec.describe 'Visiting the category page' do
  before do
    retailer = spree_retailer
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)

    category_taxonomy = create(:taxonomy, name: 'Category')
    @category_taxon = create(:taxon, taxonomy: category_taxonomy)
  end

  xit 'renders the product by category' do
    visit retailer_list_products_by_category_path(category: @category_taxon.name)
    expect(page).to have_current_path(
      retailer_list_products_by_category_path(category: @category_taxon.name)
    )

    expect(page).to have_content @category_taxon.name
  end

  context 'when the category is NOT being followed yet' do
    xit 'displays the FOLLOW button' do
      visit retailer_list_products_by_category_path(category: @category_taxon.name)
      expect(page).to have_button('FOLLOW')
      expect(spree_retailer).not_to be_following(@category_taxon)
    end

    describe 'clicking the FOLLOW button' do
      xit 'displays the UNFOLLOW button', js: true do
        visit retailer_list_products_by_category_path(category: @category_taxon.name)
        click_button 'FOLLOW'
        expect(page).to have_button('UNFOLLOW')
        expect(spree_retailer.reload).to be_following(@category_taxon)
      end
    end
  end

  context 'when the category is ALREADY being followed by spree_retailer' do
    before { spree_retailer.follow(@category_taxon) }

    xit 'displays the UNFOLLOW button' do
      visit retailer_list_products_by_category_path(category: @category_taxon.name)
      expect(page).to have_button('UNFOLLOW')
      expect(spree_retailer).to be_following(@category_taxon)
    end

    describe 'clicking the UNFOLLOW button' do
      xit 'displays the FOLLOW button', js: true do
        visit retailer_list_products_by_category_path(category: @category_taxon.name)
        click_button 'UNFOLLOW'
        expect(page).to have_button('FOLLOW')
        expect(spree_retailer.reload).not_to be_following(@category_taxon)
      end
    end
  end

  describe 'visiting the category licenses' do
    before do
      license_taxonomy = create(:taxonomy, name: 'License')
      @license_taxon = create(:taxon, taxonomy: license_taxonomy)
      @another_license_taxon = create(:taxon, taxonomy: license_taxonomy)

      # set license and category taxons on first and second products
      @first_product, @second_product = create_list(:spree_product, 2)
      @first_product.taxons << @category_taxon
      @first_product.taxons << @license_taxon

      @second_product.taxons << @category_taxon
      @second_product.taxons << @license_taxon
    end

    context 'when clicking on license that has product' do
      # it 'displays the products in the selected license under the current category' do
      #   visit retailer_license_for_category_path(
      #     category: @category_taxon.name, l: @license_taxon.id
      #   )

      #   expect(page).to have_selector('div.media-item', count: 2)
      # end
    end

    context 'when clicking on license that has NO product' do
      # it 'displays no product' do
      #   visit retailer_license_for_category_path(
      #     category: @category_taxon.name, l: @another_license_taxon.id
      #   )

      #   expect(page).to have_content 'No Products Found'
      # end
    end
  end
end
