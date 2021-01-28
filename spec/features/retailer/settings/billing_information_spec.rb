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
  end

  after { StripeMock.stop }

  describe 'visiting the billing information page' do
    it 'renders billing information page with status 200' do
      visit retailer_settings_billing_information_path

      expect(page).to have_current_path(retailer_settings_billing_information_path)
      expect(page).to have_http_status(200)
      expect(page).to have_content('Billing Information')
    end

    context 'when no card exist for strippable customer' do
      it 'sets an alert flash with message' do
        visit retailer_settings_billing_information_path

        expect(page).to have_content 'You currently do not have any credit cards on file'
        expect(page).to have_css 'div.alert.alert-warning'
      end
    end

    context 'when 2 card are set for customer' do
      before do
        StripeService.create_stripe_customer(spree_retailer)
        StripeService.add_card_to_customer(
          spree_retailer.stripe_customer, stripe_helper.generate_card_token
        )

        StripeService.add_card_to_customer(
          spree_retailer.stripe_customer, stripe_helper.generate_card_token
        )
      end

      it 'does NOT set alert flash message' do
        visit retailer_settings_billing_information_path

        expect(page).to have_css('.credit-card-information', count: 2)
        expect(page).to have_no_content 'You currently do not have any credit cards on file'
      end
    end
  end

  describe 'adding credit card' do
    context 'when valid card is added' do
      before do
        allow_any_instance_of(Supplier::SettingsController).to receive(:params).
          and_return(token: stripe_helper.generate_card_token)
      end

      it 'adds a new credit card for customer', js: true do
        visit retailer_settings_billing_information_path

        # within('form#stripe-payment-form') do
        #   within('div#card-element') do
        #     Stripe element not getting rendered on CircleCI
        #     within_frame(find('iframe')) do
        #       fill_in 'cardnumber', with: '‎4242 4242 4242 4242'
        #       fill_in 'exp-date', with: "11/#{2.years.from_now}"
        #       fill_in 'cvc', with: '111'
        #       fill_in 'postal', with: '91919'
        #     # end
        #   end

        #   click_button 'Add Credit Card'
        #   wait_for_ajax
        #   save_and_open_page
        # end

        # first('div.alert-success', wait: 3)
        # expect(page).to have_content('Credit card successfully added')
      end
    end
  end
end
