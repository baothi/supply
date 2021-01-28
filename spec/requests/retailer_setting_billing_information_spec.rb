require 'rails_helper'

RSpec.describe 'Retailer Setting', type: :request do
  before do
    StripeMock.start

    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )

    # allow_any_instance_of(Spree::Retailer).to receive(:owner_user).
    #   and_return(spree_retailer.users.first)
  end

  after { StripeMock.stop }

  describe 'GET /retailer/settings/billing_information' do
    it 'renders the billing information page' do
      get 'http://localhost:3000/retailer/settings/billing_information'
      expect(response).to have_http_status(200)
      expect(response).to render_template(:billing_information)
    end
  end

  describe 'POST /retailer/payments/save_billing_card' do
    before do
      StripeService.create_stripe_customer(spree_retailer)
    end

    context 'when a valid card_token is provided' do
      it 'creates and saves card for the customer' do
        post 'http://localhost:3000/retailer/payments/save_billing_card',
             params: {
               token: stripe_helper.generate_card_token
             }
        expect(flash[:notice]).to include 'Credit card successfully added'
        expect(spree_retailer.stripe_customer.stripe_cards.count).to eq 1
      end
    end

    # context 'when an INVALID card_token is provided' do
    #   it 'fails creating card for customer' do
    #     StripeMock.prepare_card_error(:card_declined, :create_card)
    #     post 'http://localhost:3000/retailer/payments/save_billing_card',
    #          params: {
    #            token: nil
    #          }
    #     expect(flash[:notice]).not_to include 'Credit card successfully added'
    #     expect(flash[:alert]).to include 'Error adding card to user'
    #     expect(response).to be have_status(301)
    #   end
    # end
  end

  describe 'PATCH #mark_card_as_default' do
    before do
      StripeService.create_stripe_customer(spree_retailer)
      StripeService.add_card_to_customer(
        spree_retailer.stripe_customer, stripe_helper.generate_card_token
      )
      @last_card = StripeService.add_card_to_customer(
        spree_retailer.stripe_customer, stripe_helper.generate_card_token
      )
    end

    context 'when changing the default billing card' do
      it 'sets a new default billing card on stripe' do
        expect(@last_card).not_to be_default
        patch 'http://localhost:3000/retailer/payments/mark_card_as_default',
              params: { id: @last_card.internal_identifier }

        expect(flash[:notice]).to include 'Card marked as default'
        expect(@last_card.reload).to be_default
      end
    end
  end

  describe 'DELETE #remove_billing_card' do
    before do
      StripeService.create_stripe_customer(spree_retailer)
      @first_card = StripeService.add_card_to_customer(
        spree_retailer.stripe_customer, stripe_helper.generate_card_token
      )
      @last_card = StripeService.add_card_to_customer(
        spree_retailer.stripe_customer, stripe_helper.generate_card_token
      )
    end

    context 'when the card id is invalid' do
      it 'sets error alert' do
        delete 'http://localhost:3000/retailer/payments/remove_billing_card',
               params: { id: -1 }

        expect(flash[:alert]).to include 'Unable to delete selected card'
        expect(spree_retailer.stripe_customer.stripe_cards.count).to be 2
      end
    end

    context 'when removing the non-default card' do
      it 'removes card from customer' do
        expect(spree_retailer.stripe_customer.stripe_cards.count).to be 2
        delete 'http://localhost:3000/retailer/payments/remove_billing_card',
               params: { id: @last_card.internal_identifier }

        expect(flash[:notice]).to include 'Card deleted successfully'
        expect(spree_retailer.stripe_customer.stripe_cards.count).to be 1
      end
    end

    context 'when removing the default card' do
      it 'removes card from customer and sets next card as default' do
        expect(@last_card).not_to be_default
        delete 'http://localhost:3000/retailer/payments/remove_billing_card',
               params: { id: @first_card.internal_identifier }

        expect(flash[:notice]).to include 'Card deleted successfully'
        expect(@last_card.reload).to be_default
        expect(spree_retailer.stripe_customer.stripe_cards.count).to be 1
      end
    end
  end
end
