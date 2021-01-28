require 'rails_helper'

RSpec.describe 'Managing Retailer Listings' do
  let (:retailer) do
    spree_retailer
  end

  let (:supplier) do
    spree_supplier
  end

  before do
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)
  end

  describe 'visiting the listings page' do
    it 'renders the listings page' do
      visit retailer_live_products_path
      expect(page).to have_current_path(
        retailer_live_products_path
      )
      expect(page).to have_content 'Live Products'
    end

    it 'paginates listings' do
      30.times do
        product = create :spree_product
        create :spree_product_listing,
               product: product,
               retailer: retailer,
               supplier: supplier,
               shopify_identifier: Faker::Code.ean
      end
      visit retailer_live_products_path
      expect(page).to have_link('1')
      expect(page).to have_content 'Next ›'
    end
  end

  describe 'Product Exports - In Progress Functionality' do
    it 'renders the in progress page' do
      visit retailer_in_progress_path
      expect(page).to have_current_path(
        retailer_in_progress_path
      )
      expect(page).to have_content 'In Progress'
      expect(page).to have_content 'Issues'
    end

    context 'for in-progress items initiated less than 15 minutes ago' do
      let!(:product1) { create :spree_product_in_stock }
      let!(:product2) { create :spree_product_in_stock }

      before do
        create :spree_product_export_process,
               retailer: retailer,
               product: product1,
               status: 'in_progress',
               updated_at: DateTime.now - 5.minutes
        create :spree_product_export_process,
               retailer: retailer,
               product: product2,
               status: 'in_progress',
               updated_at: DateTime.now - 5.minutes
      end

      it 'renders the correct items on the in progress page' do
        visit retailer_in_progress_path

        within('div#in_progress_list') do
          expect(page).to have_content("#{product1.name}")
          expect(page).to have_content("#{product2.name}")
        end
      end

      it 'does not allow cancellation of items initiated less than 15 mins ago' do
        expect(page).not_to have_css('.cancel-export-button')
      end
    end

    context 'for in-progress items initiated more than 15 minutes ago' do
      let!(:product1) { create :spree_product_in_stock }
      let!(:product2) { create :spree_product_in_stock }

      before do
        create :spree_product_export_process,
               retailer: retailer,
               product: product1,
               status: 'in_progress',
               updated_at: DateTime.now - 17.minutes
        create :spree_product_export_process,
               retailer: retailer,
               product: product2,
               status: 'in_progress',
               updated_at: DateTime.now - 25.minutes
      end

      it 'renders the correct items on the in progress page - in errors section' do
        visit retailer_in_progress_path

        within('div#error_list') do
          expect(page).to have_content("#{product1.name}")
          expect(page).to have_content("#{product2.name}")
        end

        expect(page).to have_button('Cancel Export', class: 'cancel-export-button', count: 2)
      end

      it 'enables export cancellation' do
        visit retailer_in_progress_path
        click_on('Cancel Export')
        expect(page).to have_css('div.alert.alert-success')
        expect(page).to have_content('Please manually remove this product')
      end

      it 'successfully processes the export cancellation' do
        visit retailer_in_progress_path

        expect { click_on('Cancel Export') }.
          to change { Spree::ProductExportProcess.in_process_of_being_exported.count }.by(-1)
      end
    end
  end
end
