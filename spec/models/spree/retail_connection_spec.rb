require 'rails_helper'

RSpec.describe Spree::RetailConnection, type: :model do
  subject { build(:spree_retail_connection) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_retail_connection, retailer_id: nil)).not_to be_valid }
      it { expect(build(:spree_retail_connection, supplier_id: nil)).not_to be_valid }
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:retailer) }
    it { is_expected.to validate_presence_of(:supplier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:supplier) }
    it { is_expected.to belong_to(:retailer) }
  end
end
