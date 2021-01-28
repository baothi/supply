require 'rails_helper'

RSpec.describe Spree::OrderIssueReport, type: :model do
  subject { build :spree_order_issue_report }

  describe 'Active Record Association' do
    it { is_expected.to belong_to(:order).class_name('Spree::Order') }
    it { is_expected.to have_one(:retailer).through(:order) }
  end

  describe 'paperclip attachment' do
    it { is_expected.to have_attached_file(:image1) }
    it { is_expected.to have_attached_file(:image2) }
  end

  describe 'Validation' do
    it { is_expected.to validate_presence_of(:description) }
    it {
      expect(subject).to validate_attachment_content_type(:image1).
        allowing('image/png', 'image/gif').
        rejecting('text/plain', 'text/xml')
    }
    it {
      expect(subject).to validate_attachment_content_type(:image2).
        allowing('image/png', 'image/gif').
        rejecting('text/plain', 'text/xml')
    }
  end

  describe '#resolved?' do
    context 'when report is resolved' do
      it 'returns true' do
        subject.amount_credited = 10
        subject.resolve_as_supplier!
        expect(subject).to be_resolved
      end
    end

    context 'when report is not resolved' do
      it 'returns false' do
        expect(subject).not_to be_resolved
      end
    end
  end

  describe 'resolution state machine' do
    context 'when order_issue_report is initialized' do
      it 'is initialized with "pending" state' do
        expect(subject).to have_state(:pending)
      end

      it 'allow "resolve_as_supplier" event' do
        expect(subject).to allow_event :resolve_as_supplier
        expect(subject).to allow_transition_to(:resolved_supplier)
      end

      it 'allow "resolve_as_hingeto" event' do
        expect(subject).to allow_event :resolve_as_hingeto
        expect(subject).to allow_transition_to(:resolved_hingeto)
      end

      it 'allow "decline" event' do
        expect(subject).to allow_event :decline
        expect(subject).to allow_transition_to(:declined)
      end
    end
  end
end
