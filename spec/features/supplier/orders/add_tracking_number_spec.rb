require 'rails_helper'

RSpec.describe 'Add Tracking Number', type: :feature do
  let(:supplier) { spree_supplier }
  let(:current_user) { supplier.users.first }
  let(:order) { create(:spree_order_ready_to_ship, supplier: spree_supplier) }

  before do
    login_as(current_user, scope: :spree_user)
    allow(order).to receive(:successfully_sent_order?).and_return true
    visit supplier_order_details_path(id: order.internal_identifier)
  end

  describe 'adding tracking to order' do
    it 'adds tracking' do
      click_on 'Add Tracking'

      within '.edit_order' do
        fill_in 'tracking_number', with: 12345
        page.check("line_item_#{order.line_items.first.internal_identifier}")
        click_on 'Add Tracking'
      end

      expect(page).to have_content 'Fulfilled line item(s)'
    end

    context 'line item not selected' do
      it 'displays error message' do
        click_on 'Add Tracking'

        within '.edit_order' do
          fill_in 'tracking_number', with: 12345
          click_on 'Add Tracking'
        end

        expect(page).to have_content 'You must select an item(s) to fulfill'
      end
    end

    context 'tracking number not filled' do
      it 'displays error message' do
        click_on 'Add Tracking'

        within '.edit_order' do
          page.check("line_item_#{order.line_items.first.internal_identifier}")
          click_on 'Add Tracking'
        end

        expect(page).to have_content 'Please enter a valid tracking number'
      end
    end
  end
end
