require 'rails_helper'

RSpec.describe StripePaymentMailer, type: :mailer do
  let(:customer) { create(:stripe_customer, strippable: spree_supplier) }
  let(:paid_invoice) { create(:stripe_invoice, stripe_customer: customer) }
  let(:failed_invoice) { create(:failed_stripe_invoice, stripe_customer: customer) }

  describe 'invoice_payment_receipt' do
    let(:mail) { StripePaymentMailer.invoice_payment_receipt(paid_invoice) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Payment receipt for subscription charge')
      expect(mail.to).to eq([customer.strippable.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Subscription plan charge receipt')
    end
  end

  describe 'invoice_failure' do
    let(:mail) { StripePaymentMailer.invoice_failure(failed_invoice) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Card Payment Failure')
      expect(mail.to).to eq([customer.strippable.email])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Hello #{customer.strippable.name},")
    end
  end
end
