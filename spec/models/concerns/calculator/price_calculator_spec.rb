require 'rails_helper'

describe :price_calculator do
  let(:wholesale_supplier) { create(:spree_supplier, instance_type: 'wholesale') }
  let(:ecommerce_supplier) { create(:spree_supplier, instance_type: 'ecommerce') }
  let(:variant) { load_fixture('shopify/variant') }
  let(:subject) { Spree::Calculator::PriceCalculator }

  describe 'calc_cost_price' do
    context 'wholesale_supplier' do
      it 'returns variant price as cost price' do
        price = variant.price
        supplier_instance_type = wholesale_supplier.instance_type
        supplier_markup_percentage = wholesale_supplier.default_markup_percentage
        expect(subject.calc_cost_price(price, supplier_instance_type, supplier_markup_percentage)).
          to eq variant.price.to_f
      end
    end

    context 'ecommerce supplier' do
      it 'returns variant price as cost price' do
        price = variant.price
        supplier_instance_type = ecommerce_supplier.instance_type
        supplier_markup_percentage = wholesale_supplier.default_markup_percentage
        expect(subject.calc_cost_price(price, supplier_instance_type, supplier_markup_percentage)).
          to eq 142.14
      end
    end
  end

  describe 'calc_price' do
    it 'returns markedup price' do
      price = variant.price
      supplier_instance_type = wholesale_supplier.instance_type
      supplier_markup_percentage = wholesale_supplier.default_markup_percentage
      expect(subject.calc_price(price, supplier_instance_type, supplier_markup_percentage)).
        to eq 212.93
    end
  end

  describe 'calc_msrp_price' do
    context 'when compare_at price is present' do
      it 'returns compare_at_price' do
        price = variant.price
        compare_at_price = variant.compare_at_price
        supplier_markup_percentage = wholesale_supplier.default_markup_percentage
        expect(subject.calc_msrp_price(
                 price,
                 compare_at_price,
                 wholesale_supplier.instance_type,
                 supplier_markup_percentage
               )).to eq variant.compare_at_price.to_f
      end
    end

    context 'when compare_at price is absent' do
      it 'calculates msrp using price and supplier markup' do
        price = variant.price
        compare_at_price = nil
        supplier_markup_percentage = wholesale_supplier.default_markup_percentage
        expect(subject.calc_msrp_price(
                 price,
                 compare_at_price,
                 wholesale_supplier.instance_type,
                 supplier_markup_percentage
               )).to eq 278.6
      end
    end
  end
end
