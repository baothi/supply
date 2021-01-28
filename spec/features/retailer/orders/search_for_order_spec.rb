require 'rails_helper'

RSpec.describe 'Retailer Search for Order Spec', type: :feature do
  context 'given a search criteria' do
    let!(:order) do
      create(:order,
             user: retailer,
             retailer: spree_retailer,
             supplier: spree_supplier,
             source: '',
             state: 'complete',
             completed_at: DateTime.now,
             variants: create_list(:variant, 2))
    end
    let!(:sample) do
      create(:order,
             user: retailer,
             retailer: spree_retailer,
             supplier: spree_supplier,
             source: 'app',
             state: 'complete',
             completed_at: DateTime.now,
             variants: create_list(:variant, 2))
    end

    before do
      retailer_login
      # Spree::Order.each(&:set_searchable_attributes)
      order.ship_address = create(:spree_address)
      order.bill_address = create(:spree_address)
      order.save
      order.set_searchable_attributes
      sample.ship_address = create(:spree_address)
      sample.bill_address = create(:spree_address)
      sample.save
      sample.set_searchable_attributes
    end

    it 'return order that match the order number' do
      visit retailer_orders_path
      expect(page).to have_content 'Orders'

      fill_in 'q', with: keyword(order.number)

      click_button 'Search'
      expect(page).to have_content order.number
    end

    it 'return sample order that match the sample order number' do
      visit retailer_orders_samples_path
      expect(page).to have_content 'Sample Orders'

      fill_in 'q', with: keyword(sample.number)

      click_button 'Search'
      expect(page).to have_content sample.number
    end

    it "returns order that match the order's variant sku" do
      visit retailer_orders_path
      expect(page).to have_content 'Orders'

      variant = order.variants.first
      fill_in 'q', with: keyword(variant.sku)

      click_button 'Search'
      expect(page).to have_content order.number
    end

    it "returns sample orders that match the sample order's variant sku" do
      visit retailer_orders_samples_path
      expect(page).to have_content 'Sample Orders'

      variant = sample.variants.first
      fill_in 'q', with: keyword(variant.sku)

      click_button 'Search'
      expect(page).to have_content sample.number
    end

    it "returns order that match the orders's product description" do
      visit retailer_orders_path
      expect(page).to have_content 'Orders'

      product = order.products.first
      fill_in 'q', with: keyword(product.description)

      click_button 'Search'
      expect(page).to have_content order.number
    end

    it "returns sample order that match the sample order's product description" do
      visit retailer_orders_samples_path
      expect(page).to have_content 'Sample Orders'

      product = sample.products.first
      fill_in 'q', with: keyword(product.description)

      click_button 'Search'
      expect(page).to have_content sample.number
    end
  end

  context 'when no Spree::Retail connection exist for the order' do
    it 'does not find the order' do
      order = create(:order, user: retailer)

      retailer_login
      visit retailer_orders_path

      expect(page).to have_content 'Orders'

      fill_in 'q', with: keyword(order.number)

      click_button 'Search'

      expect(page).to have_content('No Orders')
      expect(page).not_to have_content order.number
    end
  end
end

def retailer
  @retailer ||= spree_retailer.users.first
end

def retailer_login
  login_as(retailer, scope: :spree_user)
end

def keyword(search_term)
  search_term.slice(0..2)
end
