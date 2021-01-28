require 'rails_helper'

RSpec.describe 'Retailer Filter Order Spec', type: :feature do
  let!(:retailer) do
    spree_retailer
  end

  let!(:current_user) do
    retailer.users.first
  end

  let!(:orders) do
    create_list(
      :spree_completed_order_with_totals,
      3,
      retailer_id: spree_retailer.id
    )
  end

  let(:nigerian_address) do
    build(:nigerian_spree_address)
  end

  before do
    orders = Spree::Order.all
    orders.each_with_index { |o, i| o.update(retailer_shopify_name: "#100#{i}") }
    login_as(current_user, scope: :spree_user)
  end

  describe 'all' do
    it 'displays all orders' do
      visit retailer_orders_path
      expect(page).to have_content '#1000'
      expect(page).to have_content '#1001'
      expect(page).to have_content '#1002'
    end
  end

  describe 'paid' do
    before do
      order = Spree::Order.find_by(retailer_shopify_name: '#1000')
      create(:payment, order_id: order.id)
    end

    it 'displays all paid orders' do
      visit retailer_orders_path

      click_on 'Paid'

      expect(page).to have_content '#1000'
      expect(page).not_to have_content '#1001'
      expect(page).not_to have_content '#1002'
    end
  end

  describe 'unpaid' do
    before do
      order = Spree::Order.find_by(retailer_shopify_name: '#1000')
      create(:payment, order_id: order.id)
    end

    it 'displays all unpaid orders' do
      visit retailer_orders_path

      click_on 'Unpaid'

      expect(page).not_to have_content '#1000'
      expect(page).to have_content '#1001'
      expect(page).to have_content '#1002'
    end
  end

  describe 'fulfilled' do
    before do
      order = Spree::Order.where(retailer_shopify_name: '#1000')
      order.update(shipment_state: 'pending')
      orders = Spree::Order.where.not(retailer_shopify_name: '#1000')
      orders.update_all(shipment_state: 'shipped')
    end

    it 'displays all fulfilled orders' do
      visit retailer_orders_path

      click_on 'Fulfilled'

      expect(page).not_to have_content '#1000'
      expect(page).to have_content '#1001'
      expect(page).to have_content '#1002'
    end
  end

  describe 'unfulfilled' do
    before do
      order = Spree::Order.where(retailer_shopify_name: '#1000')
      order.update(shipment_state: 'pending')
    end

    it 'displays all unfulfilled orders' do
      visit retailer_orders_path

      click_link 'Unfulfilled'

      expect(page).to have_content '#1000'
      expect(page).not_to have_content '#1001'
      expect(page).not_to have_content '#1002'
    end
  end

  describe 'international' do
    before do
      create(:order,
             user: current_user,
             retailer: retailer,
             supplier: create(:spree_supplier, name: 'Bioworld'),
             source: '',
             retailer_shopify_name: '#1006',
             state: 'complete',
             completed_at: DateTime.now, ship_address: nigerian_address,
             variants: create_list(:spree_variant_with_quantity, 2))
    end

    it 'displays all international orders' do
      visit retailer_orders_path

      click_link 'International'

      expect(page).to have_content '#1006'
      expect(page).not_to have_content '#1000'
      expect(page).not_to have_content '#1001'
      expect(page).not_to have_content '#1002'
    end
  end
end
