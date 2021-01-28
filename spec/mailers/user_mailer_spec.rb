require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:supplier) { spree_supplier }
  let(:retailer) { spree_retailer }
  let(:new_user) do
    user = build(:spree_user)
    role = build(:spree_role)
    Spree::TeamMember.create(teamable: supplier, user: user, role: role)
    user
  end

  describe 'welcome_new_user' do
    let(:mail) { UserMailer.welcome_new_user(retailer, new_user, 'password', retailer.id) }

    it 'renders the headers' do
      expect(mail.subject).to include 'Your Credentials for TeamUp'
      expect(mail.to).to eq([new_user.email])
      expect(mail.from).to include ENV['NOREPLY_EMAIL']
    end

    it 'renders the body' do
      # expect(mail.body.encoded).to include(retailer.name)
      expect(mail.body.encoded).to include('Welcome to TeamUp!')
    end
  end

  describe 'invite_new_user' do
    let(:mail) { UserMailer.invite_new_user(retailer, new_user, 'password', retailer.id) }

    it 'renders the headers' do
      expect(mail.subject).to include 'Your Credentials for TeamUp'
      expect(mail.to).to eq([new_user.email])
      expect(mail.from).to include ENV['NOREPLY_EMAIL']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Hey #{new_user.first_name}")
      expect(mail.body.encoded).to include(retailer.name)
    end
  end

  describe 'reset_password_instructions' do
    let(:mail) { UserMailer.reset_password_instructions(new_user, 'password-reset-token') }

    it 'renders the headers' do
      expect(mail.subject).to be_a String
      expect(mail.to).to eq([new_user.email])
      expect(mail.from).to include ENV['NOREPLY_EMAIL']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Hey #{new_user.first_name}")
      expect(mail.body.encoded).to match('reset your password')
    end
  end

  describe '.unpaid_orders' do
    let(:retailer) do
      retailer = create(:spree_retailer)
      @orders = create_list(:spree_order, 2, retailer: retailer, completed_at: Time.now)
      retailer
    end

    let(:mail) { UserMailer.unpaid_orders(retailer) }

    it 'renders the headers' do
      expect(mail.subject).to be_a String
      expect(mail.to).to eq([retailer.email])
      expect(mail.from).to include ENV['NOREPLY_EMAIL']
    end

    it 'renders the body' do
      # expect(mail.body.encoded).to match("Hello #{retailer.name}")
      expect(mail.body.encoded).to include('2 unpaid')
      expect(mail.body.encoded).to include("#{@orders.first.number}")
      expect(mail.body.encoded).to include("#{@orders.last.number}")
    end
  end
end
