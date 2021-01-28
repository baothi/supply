require 'rails_helper'

RSpec.describe 'Reported Order', type: :feature do
  let!(:supplier) do
    spree_supplier
  end

  let!(:current_user) do
    supplier.users.first
  end

  before do
    login_as(current_user, scope: :spree_user)
    @order = create(:spree_shipped_order, supplier: spree_supplier)
    @order_issue = create(:spree_order_issue_report, order: @order)
  end

  describe 'Visiting reported order page' do
    it 'displays list of reported orders' do
      visit supplier_orders_reported_path
      expect(page).to have_content('Reported Orders')
      expect(page).to have_content(@order.supplier_shopify_order_name)
    end
  end

  describe 'Viewing reported order' do
    it 'display order issue details' do
      visit supplier_orders_reported_path
      expect(page).to have_content(@order.supplier_shopify_order_name)
      click_on('View')

      expect(page).to have_content('Order Report Details')
      expect(page).to have_content(@order_issue.description)
    end

    context 'when order issue is not resolved' do
      it 'displays action buttons' do
        visit supplier_orders_reported_path
        click_on('View')

        expect(page).to have_content('Approve')
      end
    end

    context 'when order issue is resolved' do
      before do
        @order_issue.decline!
      end

      it 'does not displays action buttons' do
        visit supplier_orders_reported_path

        click_on(@order.supplier_shopify_order_name)

        expect(page).to have_no_content('Approve')
      end
    end
  end
end
