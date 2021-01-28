require 'rails_helper'

RSpec.describe Spree::TeamMember, type: :model do
  subject { build(:spree_team_member) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:teamable) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:teamable) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:role) }
  end

  describe '.mailboxer_name' do
    # it { expect(subject.mailboxer_name).to include "#{subject.user.full_name}" }
  end

  describe '.mailboxer_email' do
    # it { expect(subject.mailboxer_email).to eql subject.user.email }
  end

  # describe '#transfer_ownership_to(member)' do
  #   before do
  #     role = create(:spree_role, name: Spree::Retailer::RETAILER_OWNER)
  #     subject.update(role: role)
  #   end
  #
  #   context 'when supplied member is nil' do
  #     it 'sets error message' do
  #       expect { subject.transfer_ownership_to(nil) }.to change(subject, :errors)
  #     end
  #
  #     it 'returns nil' do
  #       expect(subject.transfer_ownership_to(nil)).to be_nil
  #     end
  #   end
  #
  #   context 'when supplier member exists on team' do
  #     let(:new_team_admin) do
  #       create(:spree_team_member, role_name: Spree::Retailer::RETAILER_ADMIN)
  #     end
  #
  #     it 'transfers owner to new_team_admin' do
  #       expect(subject.user.retailer_owner?).to be true
  #       expect(new_team_admin.user.retailer_owner?).to be false
  #
  #       subject.transfer_ownership_to(new_team_admin)
  #       expect(new_team_admin.user.reload.retailer_owner?).to be true
  #       expect(subject.user.reload.retailer_owner?).to be false
  #     end
  #   end
  # end
end
