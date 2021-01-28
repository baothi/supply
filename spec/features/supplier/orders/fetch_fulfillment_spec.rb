require 'rails_helper'

RSpec.describe 'fetch fulfillment', type: :feature do
  let(:supplier) { spree_supplier }
  let(:current_user) { supplier.users.first }
  let(:order) { create(:spree_order_ready_to_ship, supplier: spree_supplier) }

  before do
    login_as(current_user, scope: :spree_user)
    allow(order).to receive(:successfully_sent_order?).and_return true
  end

  describe 'fetch tracking number from shopify' do
    before { visit supplier_order_details_path(id: order.internal_identifier) }

    it 'checks for fulfillment' do
      click_on 'Fetch Tracking from Shopify'

      expect(page).to have_content 'Checking for fulfillment update'
    end

    context 'order already fulfilled' do
      before do
        order.line_items.each { |l| l.fulfill_shipment(123456789) }
        # binding.pry
        visit supplier_order_details_path(id: order.internal_identifier)
      end

      it 'hides fetch tracking number button' do
        expect(page).not_to have_link 'Fetch Tracking from Shopify'
      end
    end
  end
end
