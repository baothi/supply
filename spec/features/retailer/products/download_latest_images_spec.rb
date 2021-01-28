require 'rails_helper'

RSpec.describe 'Download latest images', type: :feature do
  before do
    current_user = spree_retailer.users.first
    current_user.update(email: 'test@hingeto.com')
    login_as(current_user, scope: :spree_user)

    @product = create(:spree_product_in_stock)
    allow_any_instance_of(Spree::Product).to receive(:approved?).and_return(true)
    visit retailer_product_details_path(product_id: @product.internal_identifier)
  end

  describe 'downloading latest images' do
    it 'downloads images' do
      click_on('Download Latest Images')
      expect(page).to have_content('Downloading images from shopify')
    end
  end
end
