require 'rails_helper'

RSpec.describe StripeInvoice, type: :model do
  subject { build(:stripe_invoice) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_invoice, invoice_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, stripe_customer: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, charge_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, customer_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, subscription_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, total: nil)).not_to be_valid }
      it { expect(build(:stripe_invoice, amount_due: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:invoice_identifier) }
    it { is_expected.to validate_presence_of(:stripe_customer) }
    it { is_expected.to validate_presence_of(:charge_identifier) }
    it { is_expected.to validate_presence_of(:customer_identifier) }
    it { is_expected.to validate_presence_of(:subscription_identifier) }
    it { is_expected.to validate_presence_of(:total) }
    it { is_expected.to validate_presence_of(:amount_due) }

    it { is_expected.to validate_uniqueness_of(:invoice_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:stripe_customer) }
    it { is_expected.to have_many(:stripe_events) }
  end

  describe '#subscription' do
    context 'when the invoice is for a subscription' do
      before do
        @sb = create(:stripe_subscription, subscription_identifier: subject.subscription_identifier)
      end

      it { expect(subject.subscription).to eql @sb }
    end

    context 'when invoice does not have subscription_identifier' do
      before { subject.update(subscription_identifier: nil) }

      it { expect(subject.subscription).to be_nil }
    end
  end

  describe '#total_in_dollars' do
    it 'return the total divide by 100' do
      expect(subject.total_in_dollars).to eql(subject.total / 100)
    end
  end

  describe '#discount' do
    context 'when no discount object is present' do
      it { expect(subject.discount).to eql({}) }
    end

    context 'when json object is stored in discount' do
      before { subject.update(discount: { 'key' => 'value' }) }

      it 'return a hash' do
        expect(subject.discount).to be_a Hash
      end

      it 'return a hash with indeferent access' do
        expect(subject.discount).to have_key(:key)
        expect(subject.discount).to have_key('key')
        expect(subject.discount[:key]).to eql 'value'
      end
    end
  end
end
