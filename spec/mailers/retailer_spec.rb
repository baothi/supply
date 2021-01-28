require 'rails_helper'

RSpec.describe RetailerMailer, type: :mailer do
  describe 'welcome' do
    let(:mail) { RetailerMailer.welcome(retailer.id) }
    let(:retailer) { create(:spree_retailer) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome to TeamUp!')
      expect(mail.from).to eq(['noreply@hingeto.com'])
      expect(mail.to).to eq([retailer.email])
    end
  end
end
