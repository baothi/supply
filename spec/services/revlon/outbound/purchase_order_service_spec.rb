require 'rails_helper'

RSpec.describe Revlon::Outbound::PurchaseOrderService, type: :service do
  subject { Revlon::Outbound::PurchaseOrderService }

  let(:order) { create(:spree_completed_order_with_totals) }
  let(:shipping_address) { order.ship_address }
  let(:billing_address) { order.bill_address }

  let!(:line_item) do
    line_item = order.line_items.first
    line_item.line_item_number = '001'
    line_item.quantity = 5
    line_item.price = 12.95
    line_item.save
    line_item
  end

  describe '#perform' do
    it 'skips orders with no line_item' do
      order.line_items = []
      order.save

      service = subject.new(orders: [order])
      expect(service.csv_content).to be_nil

      ro = service.perform

      expect(ro.success).to be_truthy
      expect(ro.message).to be_nil
      expect(service.csv_content).to be_blank
    end

    it 'raises an error if all the orders to belong to same supplier' do
      orders = create_list(:spree_completed_order_with_totals, 5, supplier_id: 3)
      rogue_order = orders.last
      rogue_order.supplier_id = rogue_order.supplier_id + 1 # Different supplier
      rogue_order.save

      expect { subject.new(orders: orders) }.
        to raise_error('All orders must belong to the same supplier (Revlon)')
    end

    it 'does not raise an error for a collection' do
      orders = create_list(:spree_completed_order_with_totals, 5, supplier_id: 2)
      service = subject.new(orders: orders)

      expect(service.csv_content).to be_nil

      ro = service.perform

      expect(ro.success).to be_truthy
      expect(ro.message).to be_nil
      expect(service.csv_content).not_to be_nil
    end

    it 'exports purchase order via csv' do
      order.reload
      service = subject.new(orders: [order])
      expect(service.csv_content).to be_nil

      ro = service.perform

      expect(ro.success).to be_truthy
      expect(ro.message).to be_nil
      expect(service.csv_content).not_to be_nil

      expect(service.csv_content).to include "BCJ#{order.number}"
      expect(service.csv_content).to include "#{line_item.name}"
      expect(service.csv_content).to include "#{line_item.line_item_number.to_i}"
      expect(service.csv_content).to include "#{line_item.price}"
      expect(service.csv_content).to include "#{shipping_address.firstname}"
      expect(service.csv_content).to include "#{shipping_address.address1}"
      expect(service.csv_content).to include '90000006' # carrier number (hardcoded temporarily)
    end
  end
end
