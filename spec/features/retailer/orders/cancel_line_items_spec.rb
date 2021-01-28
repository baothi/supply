require 'rails_helper'

RSpec.describe 'Canceling Order Line Items', type: :feature do
  let(:current_user) do
    spree_retailer.users.first
  end

  let(:initial_items_count) { 5 }

  let(:order) do
    create(
      :spree_completed_order_with_totals,
      retailer_id: spree_retailer.id,
      line_items_count: initial_items_count
    )
  end

  before do
    current_user.update(email: 'user@hingeto.com')
    login_as(current_user, scope: :spree_user)
    visit retailer_order_details_path(id: order.internal_identifier)
  end

  it 'displays the order details for a valid order' do
    expect(page).to have_content "Order #{order.retailer_shopify_name}"
    expect(page).to have_content order.shipping_address.full_name
    expect(page).to have_content order.line_items.first.variant.name
    expect(page).to have_content order.line_items.first.variant.internal_identifier
  end

  it 'displays the print button' do
    expect(page).to have_button 'Print'
  end

  it 'displays the "Not Paid" tag' do
    expect(page).to have_selector('span.tag.tag-danger', text: 'Not paid')
  end

  it 'display order total' do
    expect(page).to have_content("Grand Total: $#{order.total_cost_price_with_shipping.round(2)}")
  end

  context 'when no line item is canceled' do
    it 'contains 5 active line items' do
      within('.page-invoice-table') do
        expect(page).to have_selector('tbody tr', count: initial_items_count)
        expect(page).to(
          have_selector('.tag.tag-warning', text: 'Unfulfilled', count: initial_items_count)
        )
        expect(page).to(
          have_selector('.btn.btn-danger.btn-xs', count: initial_items_count)
        )
      end
    end
  end

  context 'when 2 items are canceled' do
    before do
      order.line_items.first.mark_as_canceled!
      order.line_items.second.mark_as_canceled!
      order.post_process_order!
      visit retailer_order_details_path(id: order.internal_identifier)
    end

    it 'contains 3 active line items' do
      active_count = initial_items_count - 2

      within('.page-invoice-table') do
        expect(page).to have_selector('tbody tr', count: initial_items_count)
        expect(page).to have_selector('.tag.tag-warning', text: 'Unfulfilled', count: active_count)
        expect(page).to(
          have_selector('.btn.btn-danger.btn-xs', count: active_count)
        )
      end
    end

    it 'contains 2 canceled line items' do
      within('.page-invoice-table') do
        expect(page).to have_selector('.tag.tag-danger', text: 'Canceled', count: 2)
      end
    end
  end

  describe 'canceling line item', js: true do
    context 'when canceling some line items' do
      let!(:original_line_items_count) { order.line_items.count }
      let!(:original_grand_total) { order.grand_total }

      it 'removes line item from orders line items' do
        within('.page-invoice-table') do
          first('button.btn.btn-danger.btn-xs').click
          find('.modal-footer button.btn.btn-danger').click
        end

        expect(page).to have_current_path(
          retailer_order_details_path(
            id: order.internal_identifier,
            internal_identifier: order.internal_identifier
          )
        )
        expect(page).to have_content 'Successfully cancelled line item'
        expect(order.reload.eligible_line_items.count).to be < original_line_items_count
        expect(order.reload.grand_total).to be < original_grand_total
      end
    end

    context 'when canceling all line items' do
      it 'does not destroy the order and redirect to order list page' do
        within('.page-invoice-table') do
          order.line_items.count.times do
            first('button.btn.btn-danger.btn-xs').click
            find('.modal-footer button.btn.btn-danger').click
          end
        end

        expect(page).to have_content "Order #{order.retailer_shopify_name}"
        expect(page).to have_current_path(
          retailer_order_details_path(
            id: order.internal_identifier,
            internal_identifier: order.internal_identifier
          )
        )
        # expect(page).to have_current_path orders_path(team_type: 'retailer')
      end
    end
  end
end
