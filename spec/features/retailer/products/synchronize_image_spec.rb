require 'rails_helper'

RSpec.describe 'Synchronize Image', type: :feature do
  before do
    retailer = spree_retailer
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)

    @product = create(:spree_product_in_stock)
    create(
      :spree_product_listing,
      product: @product,
      retailer: spree_retailer,
      supplier: spree_supplier
    )
    visit retailer_product_details_path(product_id: @product.internal_identifier)
  end

  describe 'Synchronize images' do
    xit 'makes call to synchronize images', js: true do
      click_on('Synchronize Images')
      find('.confirm-sync-image-button').click
      expect(page).to have_content('Synchronizing images with your store')
    end
  end
end
