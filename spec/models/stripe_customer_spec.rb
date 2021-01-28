require 'rails_helper'

RSpec.describe StripeCustomer, type: :model do
  subject { build(:stripe_customer) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_customer, customer_identifier: nil)).not_to be_valid }
      # it { expect(build(:stripe_customer, strippable: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    # it { is_expected.to validate_presence_of(:strippable) }
    it { is_expected.to validate_presence_of(:customer_identifier) }

    # it { is_expected.to validate_uniqueness_of(:strippable) }
    it { is_expected.to validate_uniqueness_of(:customer_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:strippable) }
    it { is_expected.to have_one(:stripe_subscription) }
    it { is_expected.to have_one(:stripe_plan).through(:stripe_subscription) }
    it { is_expected.to have_many(:stripe_invoices) }
    it { is_expected.to have_many(:stripe_cards) }
  end
end
