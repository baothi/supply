require 'rails_helper'

RSpec.describe StripeSubscription, type: :model do
  subject { build(:stripe_subscription) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_subscription, subscription_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_subscription, plan_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_subscription, customer_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_subscription, stripe_customer: nil)).not_to be_valid }
      it { expect(build(:stripe_subscription, stripe_plan: nil)).not_to be_valid }
      it { expect(build(:stripe_subscription, status: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:subscription_identifier) }
    it { is_expected.to validate_presence_of(:plan_identifier) }
    it { is_expected.to validate_presence_of(:customer_identifier) }
    it { is_expected.to validate_presence_of(:stripe_customer) }
    it { is_expected.to validate_presence_of(:stripe_plan) }
    it { is_expected.to validate_presence_of(:status) }

    it { is_expected.to validate_uniqueness_of(:subscription_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:stripe_customer) }
    it { is_expected.to belong_to(:stripe_plan) }
    it { is_expected.to have_many(:stripe_events) }
  end
end
