require 'rails_helper'

RSpec.describe 'Payments and Subscription', type: :feature do
  before do
    StripeMock.start

    login_as(spree_retailer.users.first, scope: :spree_user)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )

    # allow_any_instance_of(Spree::Supplier).to receive(:owner_user).
    #   and_return(spree_retailer.users.first)

    plan1 = stripe_helper.create_plan(id: 'first_plan', amount: 1500)
    create(:stripe_plan, plan_identifier: plan1.id, name: plan1.name, amount: plan1.amount)

    plan2 = stripe_helper.create_plan(id: 'second_plan', amount: 2500)
    create(:stripe_plan, plan_identifier: plan2.id, name: plan2.name, amount: plan2.amount)
  end

  after { StripeMock.stop }

  describe 'visiting the payments page' do
    # it 'renders payments page with status 200' do
    #   visit retailer_payments_path
    #
    #   expect(page).to have_current_path(retailer_payments_path)
    #   expect(page).to have_http_status(200)
    #   expect(page).to have_content('Payments')
    #   # expect(page).to have_content('Edit Plan')
    # end

    # it 'lists buttons for selecting available/active plans' do
    #   visit retailer_payments_path
    #
    #   expect(page).to have_link('Select Plan', count: 2)
    # end

    context 'when a card is set for customer' do
      before do
        StripeService.create_stripe_customer(spree_retailer)
        StripeService.add_card_to_customer(
          spree_retailer.stripe_customer, stripe_helper.generate_card_token
        )
      end

      it 'does NOT display no card warning' do
        visit retailer_payments_path
        expect(page).to have_no_content 'No Credit Card on File'
        expect(page).to have_no_css 'div.alert.alert-danger'
      end
    end

    context 'when a customer only has one default card' do
      before do
        StripeService.create_stripe_customer(spree_retailer)
        StripeService.add_card_to_customer(
          spree_retailer.stripe_customer, stripe_helper.generate_card_token
        )
      end

      it 'displays page properly' do
        visit retailer_payments_path
        expect(page).to have_content 'Default'
      end
    end

    context 'when a customer has multiple cards' do
      before do
        StripeService.create_stripe_customer(spree_retailer)
        3.times do
          StripeService.add_card_to_customer(
            spree_retailer.stripe_customer, stripe_helper.generate_card_token
          )
        end
      end

      it 'displays page properly' do
        visit retailer_payments_path
        expect(page).to have_content 'Default'
        expect(page).to have_content 'Mark As Default'
      end
    end
  end

  describe 'selecting a plan' do
    # context 'when card does NOT exist for customer' do
    #   it 'redirects to billing information page' do
    #     visit retailer_payments_path
    #     first(:link, 'Select Plan').click
    #
    #     expect(page).to have_current_path retailer_settings_billing_information_path
    #     expect(page).to have_content 'Please enter your billing information'
    #     expect(page).to have_css 'div.alert.alert-danger'
    #   end
    # end

    # context 'when card exist for customer' do
    #   before(:each) do
    #     StripeService.create_stripe_customer(spree_retailer)
    #     StripeService.add_card_to_customer(
    #       spree_retailer.stripe_customer, stripe_helper.generate_card_token
    #     )
    #   end
    #
    #   it 'creates customers subscription and sets success message' do
    #     visit retailer_payments_path
    #     first(:link, 'Select Plan').click
    #
    #     expect(page).to have_current_path retailer_payments_path
    #     expect(page).to have_content 'Your subscription plan has been set successfully'
    #     expect(page).to have_css 'div.alert.alert-success'
    #   end
    # end
  end
end
