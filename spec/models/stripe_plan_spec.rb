require 'rails_helper'

RSpec.describe StripePlan, type: :model do
  subject { build(:stripe_plan) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_plan, plan_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_plan, name: nil)).not_to be_valid }
      it { expect(build(:stripe_plan, amount: nil)).not_to be_valid }
      it { expect(build(:stripe_plan, currency: nil)).not_to be_valid }
      it { expect(build(:stripe_plan, interval: nil)).not_to be_valid }
      it { expect(build(:stripe_plan, interval_count: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:plan_identifier) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:interval) }
    it { is_expected.to validate_presence_of(:interval_count) }

    it { is_expected.to validate_uniqueness_of(:plan_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to have_many(:stripe_subscriptions) }
    it { is_expected.to have_many(:stripe_customers) }
    it { is_expected.to have_many(:stripe_events) }
  end

  describe '#current_for?' do
    context 'when plan is current for given strippable' do
      let(:strippable) do
        create(:stripe_subscription, stripe_plan: subject)
        subject.stripe_customers.first.strippable
      end

      it { expect(subject).to be_current_for(strippable) }
    end

    context 'when it not the plan for a random new supplier' do
      let(:strippable) { build(:spree_supplier) }

      it { expect(subject).not_to be_current_for(strippable) }
    end
  end

  describe '.active' do
    before do
      create_list(:stripe_plan, 2)
      create(:stripe_plan, active: false)
    end

    it 'returns 3 as count of all plans' do
      expect(StripePlan.count).to be 3
    end

    it 'returns 2 for count of active plans' do
      expect(StripePlan.active.count).to be 2
    end
  end
end
