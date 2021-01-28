require 'rails_helper'

RSpec.describe 'Bulk Payment Spec', type: :feature do
  let!(:retailer) do
    spree_retailer
  end

  let!(:supplier) do
    spree_supplier
  end

  let!(:current_user) do
    retailer.users.first
  end

  before do
    login_as(current_user, scope: :spree_user)

    create_list(
      :spree_completed_order_with_totals,
      5,
      retailer: retailer,
      supplier: supplier
    )
  end

  context 'when selected orders contain unpaid orders' do
    it 'pays for orders in bulk', js: true do
      visit retailer_orders_path
      expect(page).to have_css('div.order-payment', visible: false)

      all('.order-batch-action-span')[1].click
      all('.order-batch-action-span')[2].click
      expect(page).to have_content('2 Orders selected')

      select 'Pay for Orders', from: 'batch_action'

      click_button 'Go'
      expect(page).to have_content 'Bulk Order Payment'

      click_button 'Make Bulk Payment'
      expect(page).to have_css('div.order-payment', visible: true)
    end
  end
end
