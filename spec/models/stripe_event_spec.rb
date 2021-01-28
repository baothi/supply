require 'rails_helper'

RSpec.describe StripeEvent, type: :model do
  subject { build(:stripe_event) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:stripe_event, event_identifier: nil)).not_to be_valid }
      it { expect(build(:stripe_event, stripe_eventable: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:stripe_eventable) }
    it { is_expected.to validate_presence_of(:event_identifier) }

    it { is_expected.to validate_uniqueness_of(:event_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:stripe_eventable) }
  end

  describe '#event_object' do
    context 'when no event_object is present' do
      it { expect(subject.event_object).to eql({}) }
    end

    context 'when json object is stored in the event_object' do
      before { subject.update(event_object: { 'key' => 'value' }) }

      it 'return a hash' do
        expect(subject.event_object).to be_a Hash
      end

      it 'return a hash with indiferent access' do
        expect(subject.event_object).to have_key(:key)
        expect(subject.event_object).to have_key('key')
        expect(subject.event_object[:key]).to eql 'value'
      end
    end
  end
end
