require 'rails_helper'

RSpec.describe Revlon::Inbound::FulfillmentService, type: :service do
  subject { Revlon::Inbound::FulfillmentService }

  let(:order_1) do
    create(:spree_order_ready_to_ship,
           number: 'DS13673404',
           line_items: [
               FactoryBot.build(
                 :spree_line_item,
                 quantity: 2,
                 line_item_number: '001',
                 variant: FactoryBot.build(:spree_variant, original_supplier_sku: 'ZXC123-A')
               ),
               FactoryBot.build(
                 :spree_line_item,
                 quantity: 3,
                 line_item_number: '002',
                 variant: FactoryBot.build(:spree_variant, original_supplier_sku: 'ZXC456-B')
               )
           ])
  end

  let(:order_2) do
    create(:spree_order_ready_to_ship,
           number: 'DS14442205',
           line_items: [
               FactoryBot.build(
                 :spree_line_item,
                 quantity: 5,
                 line_item_number: '100',
                 variant: FactoryBot.build(:spree_variant, original_supplier_sku: 'ASD123-B')
               ),
               FactoryBot.build(
                 :spree_line_item,
                 quantity: 4,
                 line_item_number: '101',
                 variant: FactoryBot.build(:spree_variant, original_supplier_sku: 'ASD456-A')
               ),
               FactoryBot.build(
                 :spree_line_item,
                 quantity: 1,
                 line_item_number: '102',
                 variant: FactoryBot.build(:spree_variant, original_supplier_sku: 'BVV456-M')
               )
           ])
  end

  let!(:shipping) { create(:spree_shipping_category_with_method) }

  let(:csv_content) { File.read("#{Rails.root}/spec/fixtures/revlon/fulfillment/asn_sample_1.csv") }

  describe '#perform', tremp: true do
    before do
      order_1.reload
      order_2.reload
      shipping.reload
    end

    it 'raises error if invalid order number provided' do
      csv_content = nil
      CSV.generate do |csv|
        csv << %w(order detail sku quantity tracking_number)
        csv << %w(JCCDS123456 001 ZXC123-A 2 1Z51062E6893884735)
        csv_content = csv.string
      end

      service = subject.new(csv_content: csv_content)
      ro = service.perform

      expect(ro.success).to be_falsey
      expect(ro.message).to include 'Order #DS123456 not found.'
    end

    it 'raises error if invalid line item association provided in csv' do
      csv_content = nil
      CSV.generate do |csv|
        csv << %w(order detail sku quantity tracking_number)
        csv << %w(JCCDS14442205 101 XXX123-A 4 1ZT675T4YW92275898;1ZW6897XYW00098770)
        csv_content = csv.string
      end

      service = subject.new(csv_content: csv_content)
      ro = service.perform

      expect(ro.success).to be_falsey
      expect(ro.message).to include 'Line item with sku XXX123-A not associated with the order.'
    end

    it 'raises error if invalid order number provided' do
      csv_content = nil
      CSV.generate do |csv|
        csv << %w(order detail sku quantity tracking_number)
        csv << %w(JCCDS13673404 001 ZXC123-A 4 1Z51062E6893884735)
        csv_content = csv.string
      end

      service = subject.new(csv_content: csv_content)
      ro = service.perform

      discrepancy_error = I18n.t('edi.discrepancy_error',
                                 quantity: order_1.line_items.first.quantity,
                                 shipped_quantity: 4)
      expect(ro.success).to be_falsey
      expect(ro.message).to include discrepancy_error
    end

    it 'successfully process orders shipping tracking csv and update order status' do
      expect(order_1.shipment_state).to eq 'ready'
      expect(order_2.shipment_state).to eq 'ready'

      service = subject.new(csv_content: csv_content)
      ro = service.perform

      expect(ro.success).to be_truthy
      expect(ro.message).to be_nil

      order_1.reload
      order_2.reload

      expect(order_1.shipment_state).to eq 'shipped'
      expect(order_2.shipment_state).to eq 'shipped'
    end
  end
end
