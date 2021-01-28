require 'rails_helper'

RSpec.describe 'Canceling Order Line Items', type: :feature do
  let(:current_user) { spree_supplier.users.first }

  let(:initial_items_count) { 5 }

  let(:order) do
    create(
      :spree_order_ready_to_ship,
      supplier_id: spree_supplier.id,
      line_items_count: initial_items_count
    )
  end

  before do
    login_as(current_user, scope: :spree_user)
    visit supplier_order_details_path(id: order.internal_identifier)
  end

  describe 'canceling line item' do
    let!(:original_grand_total) { order.grand_total }
    let!(:line_item) { order.line_items.first }

    it 'removes line item from orders line items', js: true do
      within('.page-invoice-table') do
        find("#cancel-#{line_item.internal_identifier}").click
      end

      click_on('Yes, Please cancel line item')

      expect(page).to have_content 'Successfully cancelled line item'
      expect(order.reload.eligible_line_items.count).to eq(initial_items_count - 1)
      expect(order.reload.grand_total).to be < original_grand_total
    end

    context 'when canceling all line items' do
      it 'does not destroy the order' do
        within('.page-invoice-table') do
          order.line_items.each do |line_item|
            find("#cancel-#{line_item.internal_identifier}").click
            click_on('Yes, Please cancel line item')
          end
        end

        expect(order.reload.eligible_line_items.count).to eq(initial_items_count)
      end
    end
  end
end
