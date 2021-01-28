require 'rails_helper'

RSpec.describe StripeCard, type: :model do
  subject { build(:stripe_card) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_card, stripe_customer: nil)).not_to be_valid }
      it { expect(build(:stripe_card, card_identifier: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:stripe_customer) }
    it { is_expected.to validate_presence_of(:card_identifier) }
    it { is_expected.to validate_presence_of(:customer_identifier) }
    it { is_expected.to validate_presence_of(:exp_year) }
    it { is_expected.to validate_presence_of(:exp_month) }
    it { is_expected.to validate_presence_of(:last4) }

    it { is_expected.to validate_uniqueness_of(:card_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:stripe_customer) }
  end

  describe '#exp_date' do
    it { expect(subject.exp_date).to include subject.exp_month.to_s }
    it { expect(subject.exp_date).to include subject.exp_year.to_s }
    it { expect(subject.exp_date).to include '/' }
  end

  describe '#last_four' do
    it { expect(subject.last_four).to include subject.last4 }
  end

  describe '#default?' do
    context 'when card is not default' do
      it { expect(subject).not_to be_default }
    end

    context 'when card is default' do
      before { subject.stripe_customer.update(default_source: subject.card_identifier) }

      it { expect(subject).to be_default }
    end
  end

  describe '#icon_css_class' do
    context 'when card is American Express' do
      before { subject.update(brand: 'American Express') }

      it { expect(subject.icon_css_class).to eql 'fa-cc-amex' }
    end

    context 'when card is NOT American Express' do
      before { subject.update(brand: 'Visa') }

      it { expect(subject.icon_css_class).to eql 'fa-cc-visa' }
    end
  end
end
