require 'rails_helper'

RSpec.describe 'Retailer Manager Errors for Order Spec', type: :feature do
  let!(:retailer) do
    spree_retailer
  end

  let!(:current_user) do
    retailer.users.first
  end

  before do
    login_as(current_user, scope: :spree_user)
  end

  let(:nigerian_address) do
    build(:nigerian_spree_address)
  end

  let(:us_address) do
    build(:us_spree_address)
  end

  let!(:order) do
    create(:order,
           user: current_user,
           retailer: retailer,
           supplier: create(:spree_supplier, name: 'Bioworld'),
           source: '',
           state: 'complete',
           completed_at: DateTime.now, ship_address: us_address,
           variants: create_list(:spree_variant_with_quantity, 2))
  end

  describe 'For US & non-US orders' do
    context 'for non US orders'  do
      it 'does not allow payment' do
        order.ship_address = nigerian_address
        order.save

        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        expect(page).to have_button 'View Errors'

        click_button 'View Errors'
        expect(page).to have_content 'We cannot ship the products in this order outside of '\
        'the US due to restrictions by the supplier.'
      end
    end

    context 'for US orders' do
      it 'does allow payment' do
        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        expect(page).not_to have_button 'View Errors'
        expect(page).not_to have_content 'We cannot ship the products in this order outside of '\
        'the US due to restrictions by the supplier.'

        expect(page).to have_button 'Order Product'
      end
    end
  end

  describe 'Inventory & Visibility Management' do
    context 'when there are no more products in inventory' do
      it 'does not allow orders with line items that are out of stock' do
        variant = order.line_items.first.variant
        variant.update_variant_stock(0)
        allow(variant).to receive(:available_quantity).and_return 0

        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        expect(page).to have_button 'View Errors'

        click_button 'View Errors'

        expect(page).to have_content 'This order contains discontinued items'
      end

      it 'does not allow orders with line items that are discontinued' do
        product = order.line_items.first.variant.product
        product.discontinue_on = DateTime.now
        product.save!

        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        click_button 'View Errors'

        expect(page).to have_button 'View Errors'
        expect(page).to have_content 'This order contains discontinued items'
      end
    end

    context 'when there are no products in inventory' do
      it 'does allow payment' do
        allow_any_instance_of(Spree::Variant).to receive(:available_quantity).and_return 5
        order.line_items.each do |line_item|
          variant = line_item.variant
          product = variant.product
          variant.update_variant_stock(5)
          variant.save

          product.discontinue_on = nil
          product.save
        end

        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        expect(page).not_to have_button 'View Errors'
        expect(page).not_to have_content 'We cannot ship outside of the US. '
        expect(page).not_to have_content 'This order contains discontinued items'
        expect(page).to have_button 'Order Product'
      end
    end
  end

  describe 'Remittance Process' do
    context 'For failed payments or orders with error state' do
      it 'does not allow payment' do
        order.raise_issue!

        visit retailer_orders_path
        expect(page).to have_content 'Orders'

        click_button 'View Errors'

        expect(page).to have_button 'View Errors'
        expect(page).to have_content 'There was an error submitting this order.'
      end
    end

    it 'can successfully clear out error message on order' do
      order.raise_issue!

      visit retailer_orders_path
      expect(page).to have_content 'Orders'

      click_button 'View Errors'

      expect(page).to have_content 'There was an error submitting this order.'

      click_link 'Clear Errors'

      expect(page).to have_content 'has been cleared of its errors'
      expect(page).to have_button 'Order Product'
      expect(page).not_to have_button 'View Errors'
    end
  end
end
