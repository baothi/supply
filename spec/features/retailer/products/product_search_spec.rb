require 'rails_helper'

RSpec.describe 'Retailer - Product Search' do
  let (:retailer) do
    spree_retailer
  end

  let (:supplier) do
    spree_supplier
  end

  before do
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)
    create(
      :permit_selling_authority,
      retailer: retailer,
      permittable: supplier
    )
  end

  describe 'visiting the search page' do
    it 'renders the search page' do
      visit retailer_products_list_path
      expect(page).to have_current_path(retailer_products_list_path)
      expect(page).to have_content 'Search for products'
    end

    it 'paginates listings' do
      products = create_list(
        :spree_product,
        30,
        supplier: supplier,
        marketplace_compliant: true,
        submission_state: 'approved'
      )
      products.each do |product|
        create(
          :permit_selling_authority,
          retailer: retailer,
          permittable: product
        )
      end
      visit retailer_products_list_path
      expect(page).to have_link('1')
      expect(page).to have_link('2')
      expect(page).to have_content 'Next ›'
      expect(page).to have_content 'Last »'
    end
  end

  describe 'using the native search' do
    it 'Only returns marketplace compliant & approved products' do
      products = create_list(
        :spree_product,
        4,
        supplier: supplier,
        marketplace_compliant: true,
        submission_state: 'approved'
      )

      products += create_list(
        :spree_product,
        3,
        supplier: supplier,
        marketplace_compliant: true,
        submission_state: 'pending_review'
      )

      products.each do |product|
        create(
          :permit_selling_authority,
          retailer: retailer,
          permittable: product
        )
      end

      visit retailer_products_list_path

      fill_in 'search_value', with: ''
      click_button('Search')

      expect(page.all('.media-item').count).to eq 4
    end

    context 'Search by Product Name' do
      before do
        @products = create_list(
          :spree_product,
          30,
          supplier: supplier,
          marketplace_compliant: true,
          submission_state: 'approved'
        )

        first_product = @products.first
        second_product = @products.second
        third_product = @products.third

        first_product.name = 'Vietnam T Shirt'
        first_product.save!
        create(
          :permit_selling_authority,
          retailer: retailer,
          permittable: first_product
        )

        second_product.name = 'Mickey Mouse Shirt'
        second_product.save!
        create(
          :permit_selling_authority,
          retailer: retailer,
          permittable: second_product
        )

        third_product.name = 'Disney Skirt'
        third_product.save!
        create(
          :permit_selling_authority,
          retailer: retailer,
          permittable: third_product
        )
      end

      it 'returns products by title on full & partial searches' do
        visit retailer_products_list_path

        fill_in 'search_value', with: 'Vietnam'
        click_button('Search')

        expect(page).to have_content('Vietnam T Shirt', count: 1)
        expect(page.all('.media-item').count).to eq 1

        # Note - fuzzy searches don't yet work.
        # For example, searching "Shi" would probably yield 0 results
        fill_in 'search_value', with: 'Shirt'
        click_button('Search')

        expect(page).to have_content('Mickey Mouse Shirt', count: 1)
        expect(page.all('.media-item').count).to eq 2
      end
    end

    context 'Filters' do
      before do
        @valid_products = create_list(
          :spree_product,
          10,
          supplier: supplier,
          marketplace_compliant: true,
          submission_state: 'approved'
        )

        @not_approved_products = create_list(
          :spree_product,
          5,
          supplier: supplier,
          marketplace_compliant: true,
          submission_state: 'pending_review'
        )

        @valid_products.each do |product|
          create(
            :permit_selling_authority,
            retailer: retailer,
            permittable: product
          )
        end

        @not_approved_products.each do |product|
          create(
            :permit_selling_authority,
            retailer: retailer,
            permittable: product
          )
        end

        @first_product = @valid_products.first
        @second_product = @valid_products.second
        @third_product = @valid_products.third

        @first_product.name = 'Vietnam T Shirt'
        @first_product.save!

        @second_product.name = 'Mickey Mouse Shirt'
        @second_product.save!

        @third_product.name = 'Disney Skirt'
        @third_product.save!

        visit retailer_products_list_path
      end

      it 'excludes items from my store while searching' do
        # First create product listing
        create(:spree_product_listing,
               product: @second_product,
               retailer: retailer,
               supplier: supplier)

        fill_in 'search_value', with: ''
        click_button('Search')
        expect(page).to have_content('Mickey Mouse Shirt', count: 1)
        expect(page.all('.media-item').count).to eq 10

        check 'exclude_shopify_products'

        fill_in 'search_value', with: ''
        click_button('Search')
        expect(page).to have_content('Mickey Mouse Shirt', count: 0)
        expect(page.all('.media-item').count).to eq 9
      end

      it 'exclude zero inventory items' do
        @first_product.update_search_attribute_value!('available_quantity', 100)
        fill_in 'search_value', with: 'Vietnam T Shirt'
        click_button('Search')
        expect(page).to have_content('Vietnam T Shirt', count: 1)

        # Anything below 5 is currently out of stock
        @first_product.update_search_attribute_value!('available_quantity', 2)
        click_button('Search')
        expect(page).to have_content('Vietnam T Shirt', count: 1)

        check 'exclude_zero_inventory'

        click_button('Search')
        expect(page).to have_content('Vietnam T Shirt', count: 0)
      end

      it 'exclude products ineligible for international sale/stores' do
        @first_product.update_search_attribute_value!('eligible_for_international_sale', true)
        fill_in 'search_value', with: 'Vietnam T Shirt'
        click_button('Search')
        expect(page).to have_content('Vietnam T Shirt', count: 1)

        @first_product.update_search_attribute_value!('eligible_for_international_sale', false)

        check 'exclude_us_only_product'

        click_button('Search')
        expect(page).to have_content('Vietnam T Shirt', count: 0)
      end
    end
  end
end
