require 'rails_helper'

RSpec.describe 'Supplier Orders Filter Spec', type: :feature do
  let(:supplier) { spree_supplier }
  let(:current_user) { supplier.users.first }

  let!(:orders) do
    create_list(:spree_order_ready_to_ship, 3, retailer: spree_retailer, supplier: supplier)
  end

  let!(:another_supplier_order) do
    create(
      :spree_order_ready_to_ship,
      supplier: create(:spree_supplier),
      supplier_shopify_order_name: '123xyz'
    )
  end

  let!(:unpaid_order) do
    create(
      :spree_completed_order_with_totals,
      supplier: supplier,
      supplier_shopify_order_name: 'unpaid123'
    )
  end

  before do
    orders.each_with_index { |o, i| o.update(supplier_shopify_order_name: "#100#{i}") }
    login_as(current_user, scope: :spree_user)

    visit supplier_orders_path
  end

  context 'all' do
    it 'displays all orders belonging to supplier' do
      expect(page).to have_content '#1000'
      expect(page).to have_content '#1001'
      expect(page).to have_content '#1002'
    end

    it 'does not display orders belonging to another supplier' do
      expect(page).to have_no_content another_supplier_order.supplier_shopify_order_name
    end

    it 'does not display unpaid orders' do
      expect(page).to have_no_content unpaid_order.supplier_shopify_order_name
    end
  end

  context 'fulfilled unfulfilled' do
    before do
      order = Spree::Order.where(supplier_shopify_order_name: '#1000')
      order.update(shipment_state: 'pending')
      orders = Spree::Order.where.not(supplier_shopify_order_name: '#1000')
      orders.update_all(shipment_state: 'shipped')
    end

    context 'fulfilled' do
      it 'displays all fulfilled orders' do
        click_on 'Fulfilled'

        expect(page).not_to have_content '#1000'

        expect(page).to have_content '#1001'
        expect(page).to have_content '#1002'
      end
    end

    context 'unfulfilled' do
      it 'displays all unfulfilled orders' do
        click_on 'Unfulfilled'

        expect(page).to have_content '#1000'

        expect(page).to have_no_content '#1001'
        expect(page).to have_no_content '#1002'
      end
    end
  end

  context 'late' do
    before do
      order = Spree::Order.find_by(supplier_shopify_order_name: '#1000')
      order.update(must_fulfill_by: Time.now - 1.days)
      orders = Spree::Order.where.not(supplier_shopify_order_name: '#1000')
      orders.update_all(must_fulfill_by: Time.now + 4.days)
    end

    it 'displays late orders' do
      click_on 'Late'

      expect(page).to have_content '#1000'

      expect(page).not_to have_content '#1001'
      expect(page).not_to have_content '#1002'
    end
  end

  context 'cancelled' do
    before do
      order = Spree::Order.find_by(supplier_shopify_order_name: '#1002')
      order.update(shipment_state: 'canceled')
    end

    it 'displays cancelled orders' do
      click_on 'Cancelled'

      expect(page).to have_content '#1002'

      expect(page).not_to have_content '#1000'
      expect(page).not_to have_content '#1001'
    end
  end

  context 'partially fulfilled' do
    before do
      order = Spree::Order.find_by(supplier_shopify_order_name: '#1000')
      order.update(shipment_state: 'partial')
    end

    it 'displays all unfulfilled orders' do
      visit supplier_orders_path

      click_on 'Partially Fulfilled'

      expect(page).to have_content '#1000'

      expect(page).not_to have_content '#1001'
      expect(page).not_to have_content '#1002'
    end
  end
end
