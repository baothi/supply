require 'rails_helper'

RSpec.describe 'Orders Search Spec', type: :feature do
  let!(:orders) do
    create_list(:spree_order_ready_to_ship, 3, retailer: spree_retailer, supplier: spree_supplier)
  end

  before do
    supplier_login

    orders.each_with_index do |o, i|
      o.update(supplier_shopify_order_name: "#100#{i}")
      o.set_searchable_attributes
    end
  end

  shared_examples 'search orders' do |q, seen_orders, unseen_orders|
    it 'returns matching orders' do
      visit supplier_orders_path

      fill_in 'q', with: q
      click_on 'Search'

      seen_orders.each do |order_number|
        expect(page).to have_content(order_number)
      end

      unseen_orders.each do |order_number|
        expect(page).to have_no_content(order_number)
      end
    end
  end

  context 'search by shopify attributes' do
    context 'supplier order number' do
      include_examples 'search orders', '#1000', ['#1000'], %w(#1001 #1002)
    end
  end

  context 'search by customer attributes' do
    let!(:order) { Spree::Order.find_by(supplier_shopify_order_name: '#1001') }
    let!(:sample) { Spree::Order.find_by(supplier_shopify_order_name: '#1002') }

    before do
      order.ship_address = create(:spree_address, address1: 'my address')
      order.bill_address = create(:spree_address)
      order.customer_email = 'test@example.com'
      order.save
      order.set_searchable_attributes

      sample.ship_address = create(:spree_address)
      sample.bill_address = create(:spree_address)
      sample.save
      sample.set_searchable_attributes
    end

    context 'shipping address' do
      include_examples 'search orders', 'my address', ['#1001'], %w(#1000 #1002)
    end

    context 'customer email' do
      include_examples 'search orders', 'test@example.com', ['#1001'], %w(#1000 #1002)
    end
  end

  context 'variant sku' do
    let(:order) { Spree::Order.find_by(supplier_shopify_order_name: '#1001') }

    before do
      line_item = order.line_items.first
      variant = line_item.variant
      variant.update(platform_supplier_sku: '123sku')
      order.set_searchable_attributes
    end

    include_examples 'search orders', '123sku', ['#1001'], %w(#1000 #1002)
  end

  context 'product_attributes' do
    let(:order) { Spree::Order.find_by(supplier_shopify_order_name: '#1002') }

    before do
      line_item = order.line_items.first
      product = line_item.variant.product
      product.update(name: 'my_product', description: 'my_description')
      order.set_searchable_attributes
    end

    context 'product name' do
      include_examples 'search orders', 'my_product', ['#1002'], %w(#1001 #1000)
    end

    context 'product description' do
      include_examples 'search orders', 'my_description', ['#1002'], %w(#1001 #1000)
    end
  end
end

def supplier_user
  spree_supplier.users.first
end

def supplier_login
  login_as(supplier_user, scope: :spree_user)
end

def keyword(search_term)
  search_term.slice(0..2)
end
