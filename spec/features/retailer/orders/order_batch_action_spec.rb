require 'rails_helper'

RSpec.describe 'Order Batch Action Spec', type: :feature do
  let!(:retailer) do
    spree_retailer
  end

  let!(:supplier) do
    spree_supplier
  end

  let!(:current_user) do
    retailer.team_members.first.user
  end

  let!(:orders) do
    create_list(
      :spree_order_ready_to_ship,
      5,
      retailer: retailer,
      supplier: supplier,
      archived_at: nil
    )
  end

  before do
  end

  context 'archive orders' do
    before do
      allow_any_instance_of(Retailer::OrdersController).
        to receive(:ensure_supplier_is_strippable).and_return(true)

      allow_any_instance_of(Retailer::BaseController).
        to receive(:authenticate_retailer!).and_return(true)

      allow_any_instance_of(Retailer::BaseController).
        to receive(:current_retailer).and_return(retailer)

      allow_any_instance_of(Retailer::BaseController).
        to receive(:confirm_paying_customer?).and_return(true)

      allow_any_instance_of(Retailer::BaseController).
        to receive(:confirm_onboarded?).and_return(true)

      # allow_any_instance_of(Retailer::OrdersController).
      #     to receive(:query_for_orders).and_return(orders)
    end

    it 'archives selected orders', js: true do
      login_as(current_user, scope: :spree_user)

      # current_user = retailer.team_members.first.user

      # puts "Current User: #{current_user.inspect}".blue
      # puts "1. Number of Orders: #{Spree::Order.count}".yellow
      # puts "Number of Orders FOr Retailer #{current_retailer.id}:
      # #{Spree::Order.for_retailer(current_retailer.id).count}"

      visit retailer_orders_path

      # binding.pry
      # puts "2. Number of Orders in Test: #{Spree::Order.count}".light_cyan

      first('.order-batch-action-span').click
      expect(page).to have_content('1 Order selected')

      select 'Archive Orders', from: 'batch_action'

      click_button 'Go'
      expect(page).to have_content 'Orders Archived'
    end
  end
end
