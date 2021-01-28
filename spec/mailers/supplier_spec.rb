require 'rails_helper'

RSpec.describe SupplierMailer, type: :mailer do
  describe 'welcome' do
    let(:mail) { SupplierMailer.welcome(supplier.id) }
    let(:supplier) { create(:spree_supplier) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome to TeamUp')
      expect(mail.from).to eq(['noreply@hingeto.com'])
      expect(mail.to).to eq([supplier.email])
    end
  end
end
