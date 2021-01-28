require 'rails_helper'

RSpec.describe ShopifyMailer, type: :mailer do
  include ActiveJob::TestHelper

  let!(:retailer) { build_stubbed(:spree_supplier) }
  let!(:message) { 'Your product export is completed' }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#add_taxon_products_to_shopify' do
    let!(:mail) do
      described_class.add_taxon_products_to_shopify(message, retailer)
    end

    context 'headers' do
      it 'renders the subject' do
        expect(mail.subject).to eq 'Bulk Product Export To Shopify'
      end

      it 'sends to the right email' do
        expect(mail.to).to eq [retailer.email]
      end

      it 'renders the from email' do
        expect(mail.from).to eq [ENV['SUPPLIER_EMAIL']]
      end

      it 'includes the word hello in the body' do
        expect(mail.body.encoded).to include 'Hello'
      end
    end
  end
end
