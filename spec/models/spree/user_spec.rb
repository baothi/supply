require 'rails_helper'

RSpec.describe Spree::User, type: :model do
  subject { build(:spree_user) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
    it { expect(subject.email).to be_a String }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_user, email: nil)).not_to be_valid }
      it { expect(build(:spree_user, password: nil)).not_to be_valid }
      # it { expect(build(:spree_user, last_name: nil)).not_to be_valid }
      # it { expect(build(:spree_user, first_name: nil)).not_to be_valid }
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe 'Response to instance methods' do
    it do
      expect(subject).to respond_to(:email, :first_name, :last_name, :phone_number,
                                    :using_temporary_password, :full_name,
                                    :send_reset_password_instructions,
                                    :send_reset_password_instructions_notification, :retailer_user?,
                                    :supplier_owner_or_admin?, :retailer_owner_or_admin?)
    end
  end

  describe 'Active model associations' do
    it { is_expected.to have_many(:long_running_jobs) }
    it { is_expected.to have_many(:team_members) }
  end

  describe '.full_name' do
    context 'when no argument is passed' do
      it 'return users full name with first name first' do
        expect(subject.full_name).to eql "#{subject.first_name} #{subject.last_name}".strip
      end
    end

    context 'when receive true as argument' do
      it 'return users full name with last name first' do
        expect(subject.full_name(true)).to eql "#{subject.last_name}, #{subject.first_name}".strip
      end
    end
  end

  describe '#retailer_user?' do
    it 'return true for user of a retailer teamable' do
      expect(spree_retailer.users.first.try(:retailer_user?)).to be_truthy
    end

    it 'return false for user of a supplier teamable' do
      expect(spree_supplier.users.first.try(:retailer_user?)).to be_falsey
    end
  end

  describe '#supplier_owner_or_admin?' do
    context 'when user is the supplier owner' do
      let(:user) do
        team_member = create(:spree_team_member, role_name: Spree::Supplier::SUPPLIER_OWNER)
        team_member.user
      end

      it 'returns true for supplier owner user' do
        expect(user).to be_supplier_owner_or_admin
      end
    end

    context 'when user is the supplier legal' do
      let(:user) do
        team_member = create(:spree_team_member, role_name: Spree::Supplier::SUPPLIER_LEGAL)
        team_member.user
      end

      it 'returns true for supplier owner user' do
        expect(user).not_to be_supplier_owner_or_admin
      end
    end
  end

  describe '#retailer_owner_or_admin?' do
    context 'when user is the retailer owner' do
      let(:user) do
        team_member = create(:spree_team_member, role_name: Spree::Retailer::RETAILER_OWNER)
        team_member.user
      end

      it 'returns true for retailer owner user' do
        expect(user).to be_retailer_owner_or_admin
      end
    end

    context 'when user is the retailer legal' do
      let(:user) do
        team_member = create(:spree_team_member, role_name: Spree::Retailer::RETAILER_LEGAL)
        team_member.user
      end

      it 'returns true for retailer owner user' do
        expect(user).not_to be_retailer_owner_or_admin
      end
    end
  end

  describe '#hingeto_user?' do
    context 'when user email is a hingeto email' do
      before { subject.update(email: 'test@hingeto.com') }

      it { expect(subject).to be_hingeto_user }
    end

    context 'when user email is NOT a hingeto email' do
      before { subject.update(email: 'test@example.com') }

      it { expect(subject).not_to be_hingeto_user }
    end
  end

  describe '.reset_password_keys' do
    it { expect(described_class.reset_password_keys).to eql %i(email) }
  end

  describe '#retailer_owner?' do
    it 'returns true if associated team member is retailer owner' do
      create(:spree_team_member, role_name: Spree::Retailer::RETAILER_OWNER, user: subject)
      expect(subject.retailer_owner?).to be true
    end

    it 'returns false if associated team member is retailer admin' do
      create(:spree_team_member, role_name: Spree::Retailer::RETAILER_ADMIN, user: subject)
      expect(subject.retailer_owner?).to be false
    end
  end
end
