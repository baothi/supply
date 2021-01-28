require 'rails_helper'

RSpec.describe 'Order Details Page', type: :feature do
  let!(:order) do
    create(:spree_order_with_line_items,
           line_items_count: 2,
           user: spree_retailer.users.first,
           retailer: spree_retailer,
           supplier: spree_supplier)
  end

  before do
    login_as(spree_retailer.users.first, scope: :spree_user)
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

  context 'when the order doesnt exit anymore' do
    before do
      identifier = order.internal_identifier
      order.destroy
      visit retailer_order_details_path(id: identifier)
    end

    it 'redirects to the orders page' do
      expect(page).to have_current_path retailer_orders_path
      expect(page).to have_content 'Order not found'
    end
  end

  context 'when order is not completed yet' do
    it 'displays the pay button' do
      expect(page).to have_button 'Pay'
    end
  end
end
