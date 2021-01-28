require 'rails_helper'

RSpec.describe SampleOrder, type: :service do
  let(:retailer) { create :spree_retailer }
  let(:supplier) { create :spree_supplier }
  let(:variant) { create :on_demand_spree_variant, is_master: false }
  let(:address) do
    {
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      address1: Faker::Address.street_address,
      city: 'Oakland',
      zipcode: Faker::Address.zip_code,
      phone: Faker::PhoneNumber.phone_number,
      name_of_state: 'California'
    }
  end
  let(:subject) do
    SampleOrder.new(retailer.id, supplier.id, variant.internal_identifier, address)
  end

  describe '#shipping_address' do
    context 'valid address params' do
      it 'creates a new address' do
        expect { subject.shipping_address }.to change { Spree::Address.count }.by(1)
      end

      it 'returns a new address' do
        expect(subject.shipping_address).to be_a Spree::Address
      end
    end

    context 'Invalid address params' do
      it 'returns nil' do
        subject = SampleOrder.new(retailer.id, supplier.id, variant.id, {})
        expect(subject.shipping_address).to be nil
      end
    end
  end

  describe '#valid_order?' do
    context 'when order has shipping address and billing address' do
      it 'returns true' do
        address = create :spree_address
        order = create :spree_order, shipping_address: address, billing_address: address
        expect(subject.valid_order?(order)).to be true
      end
    end

    context 'when order has no shipping address or billing address' do
      it 'returns error message' do
        order = create :spree_order
        order.bill_address = nil
        order.ship_address = nil
        expect { subject.valid_order?(order) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#perform' do
    it 'initiates order creation' do
      expect(subject).to receive(:create_order)
      subject.perform
    end
  end

  describe '#create_order' do
    before do
      Spree::StockItem.update_all(count_on_hand: 10)
    end

    context 'when retailer is eligible for free shipping' do
      it 'does not set shipping costs' do
        allow(retailer).to receive(:eligible_for_sample_order_free_shipping?).
          and_return true
        expect(subject).not_to receive(:set_costs)
        subject.create_order
      end
    end

    context 'when retailer is not eligible for free shipping' do
      it 'sets shipping costs' do
        allow_any_instance_of(Spree::Retailer).
          to receive(:eligible_for_sample_order_free_shipping?).and_return false
        # allow_any_instance_of(Spree::Order).to receive(:save!).and_return true
        expect(subject).to receive(:set_costs)
        subject.create_order
      end
    end
  end
end
