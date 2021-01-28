require 'rails_helper'

RSpec.describe 'Visiting product details page', type: :feature do
  before do
    current_user = spree_retailer.users.first
    login_as(current_user, scope: :spree_user)

    @product = create(:spree_product_in_stock)
    allow_any_instance_of(Spree::Product).to receive(:approved?).and_return(true)
  end

  describe 'image management' do
    describe 'hingeto user' do
      before do
        current_user = spree_retailer.users.first
        current_user.update(email: 'test@hingeto.com')
        login_as(current_user, scope: :spree_user)
        visit retailer_product_details_path(product_id: @product.internal_identifier)
      end

      it 'displays button to download latest images' do
        expect(page).to have_button('Download Latest Images')
      end
    end

    describe 'when non hingeto user' do
      context 'when product is added to shopify' do
        before do
          create(
            :spree_product_listing,
            product: @product,
            retailer: spree_retailer,
            supplier: spree_supplier
          )
          visit retailer_product_details_path(product_id: @product.internal_identifier)
        end

        it 'displays synchronize images button' do
          expect(page).to have_button('Synchronize Images')
        end
      end

      context 'when product is not added to shopify' do
        it 'does not display synchronize images button' do
          visit retailer_product_details_path(product_id: @product.internal_identifier)
          expect(page).not_to have_button('Synchronize Images')
        end
      end
    end
  end
end
