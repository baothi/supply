require 'rails_helper'

RSpec.describe Spree::LineItem, type: :model do
  subject { build :spree_line_item }

  let(:five_years_ago) { DateTime.now - 5.years }
  let(:today) { DateTime.now }
  let(:retailer) { create :spree_retailer }

  it_behaves_like 'an internal_identifiable model'

  describe 'Active Record Association' do
    it { is_expected.to belong_to(:supplier) }
    it { is_expected.to belong_to(:retailer) }
  end

  describe '#mark_fulfillment_time!' do
    context 'when forced is false' do
      it 'can set value of fulfill_at' do
        line_item = create :spree_line_item,
                           fulfilled_at: DateTime.now
        line_item.mark_fulfillment_time!(today, false)
        expect(line_item.fulfilled_at&.utc.to_s).not_to be_nil
      end

      it 'does not overwrite existing values of fulfill_at' do
        line_item = create :spree_line_item,
                           fulfilled_at: five_years_ago
        line_item.mark_fulfillment_time!(today, false)
        expect(line_item.fulfilled_at&.utc.to_s).not_to eq today.utc.to_s
        expect(line_item.fulfilled_at&.utc.to_s).to eq five_years_ago.utc.to_s
      end
    end

    context 'when forced is true' do
      it 'can set value of fulfill_at' do
        line_item = create :spree_line_item,
                           fulfilled_at: DateTime.now
        line_item.mark_fulfillment_time!(today, true)
        expect(line_item.fulfilled_at).not_to be_nil
      end
      it 'can override the value of fulfill_at' do
        line_item = create :spree_line_item,
                           fulfilled_at: five_years_ago

        line_item.mark_fulfillment_time!(today, true)
        line_item.reload
        expect(line_item.fulfilled_at&.utc.to_s).not_to eq five_years_ago.utc.to_s
        expect(line_item.fulfilled_at&.utc.to_s).to eq today.utc.to_s
      end
    end
  end

  describe '#fulfill_shipment' do
    context 'when an order is already shipped or cancelled' do
      it 'does not try to update the shipment dates' do
        line_item = create :spree_line_item,
                           fulfilled_at: five_years_ago
        allow(line_item).to receive(:order_already_shipped_or_cancelled?).and_return(true)
        line_item.mark_fulfillment_time!(today)
        expect(line_item.fulfilled_at&.utc.to_s).not_to eq today.utc.to_s
        expect(line_item.fulfilled_at&.utc.to_s).to eq five_years_ago.utc.to_s
      end
    end

    context 'when an order is not yet shipped' do
      it 'does update the shipment date on the line item' do
        line_item = create :spree_line_item,
                           fulfilled_at: nil
        allow(line_item).to receive(:order_already_shipped_or_cancelled?).and_return(false)
        line_item.mark_fulfillment_time!(today)
        expect(line_item.fulfilled_at&.utc.to_s).to eq today.utc.to_s
      end
    end
  end
end
