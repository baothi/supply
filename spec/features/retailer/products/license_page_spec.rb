require 'rails_helper'

RSpec.describe "Visiting the License's products list page" do
  before do
    @retailer = spree_retailer
    current_user = @retailer.users.first
    login_as(current_user, scope: :spree_user)

    license_taxonomy = create(:taxonomy, name: 'License')
    @license_taxon = create(:taxon, taxonomy: license_taxonomy)
  end

  it 'renders the list product by license page' do
    visit retailer_list_products_by_license_path(license: @license_taxon.slug)
    expect(page).to have_current_path(
      retailer_list_products_by_license_path(license: @license_taxon.slug)
    )

    expect(page).to have_content @license_taxon.name
  end

  describe 'visiting the license categories' do
    before do
      category_taxonomy = create(:taxonomy, name: 'Platform Category')
      @category_taxon = create(:taxon, taxonomy: category_taxonomy)
      @another_category_taxon = create(:taxon, taxonomy: category_taxonomy)

      # set license and category taxons on first and second products
      @first_product, @second_product =
        create_list(
          :spree_product,
          2,
          marketplace_compliant: true,
          submission_state: 'approved'
        )

      create(:permit_selling_authority, retailer: @retailer, permittable: @first_product)
      create(:permit_selling_authority, retailer: @retailer, permittable: @second_product)

      @first_product.taxons << @license_taxon
      @first_product.taxons << @category_taxon

      @second_product.taxons << @license_taxon
      @second_product.taxons << @category_taxon

      @first_product.save!
      @second_product.save!
    end

    context 'when clicking on category that has product' do
      it 'displays the products in the selected category under the current license' do
        visit retailer_list_products_by_license_path(
          license: @license_taxon.slug, cat_id: @category_taxon.id
        )

        expect(page).to have_selector('div.media-item', count: 2)
        expect(page).to have_content(@category_taxon.name)
        expect(page).to have_content(@license_taxon.name)
      end
    end

    context 'when clicking on category that has NO product' do
      it 'displays the products in the selected category under the current license' do
        visit retailer_list_products_by_license_path(
          license: @license_taxon.slug, cat_id: @another_category_taxon.id
        )

        expect(page).to have_content 'No Products Found'
      end
    end
  end
end
