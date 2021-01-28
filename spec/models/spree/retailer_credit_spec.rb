require 'rails_helper'

RSpec.describe Spree::RetailerCredit, type: :model do
  subject { build :spree_retailer_credit, retailer: spree_retailer }

  describe 'Model Validity' do
    it { is_expected.to be_valid }
  end

  columns = %i(retailer_id by_supplier by_hingeto)

  columns.each do |column|
    it { is_expected.to have_db_column column }
  end

  methods = %i(has_supplier_credit? has_hingeto_credit? total_available_credit has_credit?)

  methods.each do |method|
    it { is_expected.to respond_to method }
  end

  describe 'Model Association' do
    it { is_expected.to belong_to(:retailer).class_name('Spree::Retailer') }
  end

  describe '#has_supplier_credit?' do
    context 'when bioworld credit exists' do
      it 'returns true' do
        subject.by_supplier = 10
        expect(subject).to have_supplier_credit
      end
    end

    context 'when bioworld credit does NOT exists' do
      it 'returns false' do
        subject.by_supplier = 0
        expect(subject).not_to have_supplier_credit
      end
    end
  end

  describe '#has_hingeto_credit?' do
    context 'when hingeto credit exists' do
      it 'returns true' do
        subject.by_hingeto = 10
        expect(subject).to have_hingeto_credit
      end
    end

    context 'when hingeto credit does NOT exists' do
      it 'returns false' do
        subject.by_hingeto = 0
        expect(subject).not_to have_hingeto_credit
      end
    end
  end

  describe '#has_credit?' do
    context 'when hingeto credit exists' do
      it 'returns true' do
        subject.by_hingeto = 10
        expect(subject).to have_credit
      end
    end

    context 'when bioworld credit exists' do
      it 'returns true' do
        subject.by_supplier = 10
        expect(subject).to have_credit
      end
    end

    context 'when neither hingeto credit nor bioworld credit exists' do
      it 'returns false' do
        subject.by_hingeto = 0
        subject.by_supplier = 0
        expect(subject).not_to have_credit
      end
    end
  end

  describe '#total_available_credit' do
    it 'returns the sum of bioworld credit and hingeto credit' do
      subject.by_hingeto = 10
      subject.by_supplier = 10
      expect(subject.total_available_credit).to eq 20.0
    end
  end
end
