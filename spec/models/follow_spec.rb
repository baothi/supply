require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'Active model associations' do
    it { is_expected.to belong_to(:followable) }
    it { is_expected.to belong_to(:follower) }
  end

  describe '#block!' do
    it { expect(subject).to respond_to(:block!) }
  end
end
