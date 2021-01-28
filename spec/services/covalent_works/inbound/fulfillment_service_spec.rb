require 'rails_helper'

RSpec.describe CovalentWorks::Inbound::FulfillmentService, type: :service do
  # let (:retail_connection) do
  #   create :spree_retail_connection,
  #          supplier_number_provided_by_retailer: '54321',
  #          edi_identifier: '129499991263'
  # end

  subject { CovalentWorks::Inbound::FulfillmentService }

  let!(:supplier) do
    create :spree_supplier,
           edi_identifier: '129499991263',
           internal_vendor_number: '54321'
  end

  let!(:order) do
    create :spree_order_with_line_items,
           purchase_order_number: 'D00004569987',
           supplier: supplier
  end

  let!(:line_item) do
    line_item = order.line_items.first
    line_item.purchase_order_number = 'D00004569987'
    line_item.line_item_number = '001'
    line_item.quantity = 5
    line_item.supplier = supplier
    line_item.save
    line_item
  end

  describe '#perform' do
    it 'raises an error for invalid supplier' do
      content = File.read("#{Rails.root}/spec/fixtures/edi/fulfillment/sample_1.xml")
      supplier.edi_identifier = '2222'
      supplier.save

      ro = subject.new(content: content).perform

      expect(ro.message).to include 'Supplier with Internal Vendor Number'
      expect(ro).not_to be_successful
    end

    it 'complains when there is a discrepancy with line item quantities' do
      line_item = order.line_items.first
      line_item.quantity = 200
      line_item.purchase_order_number = 'D00004569987'
      line_item.line_item_number = '001'
      line_item.supplier = supplier
      line_item.save

      content = File.read("#{Rails.root}/spec/fixtures/edi/fulfillment/sample_1.xml")
      ro = subject.new(content: content).perform
      expect(ro.message).to include 'There is a discrepancy'
      expect(ro).not_to be_successful
    end

    it 'does not raise an error for a valid supplier' do
      first_shipping_method = Spree::ShippingMethod.first
      allow(
        Spree::ShippingMethod
      ).to receive(:find_by_service_code!).and_return first_shipping_method
      content = File.read("#{Rails.root}/spec/fixtures/edi/fulfillment/sample_1.xml")
      ro = subject.new(content: content).perform
      expect(ro).to be_successful
    end
  end
end
