require 'rails_helper'

RSpec.describe Spree::ProductExportProcess, type: :model do
  subject { build(:spree_product_export_process) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_product_export_process, retailer_id: nil)).not_to be_valid }
      it { expect(build(:spree_product_export_process, product_id: nil)).not_to be_valid }
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:retailer) }
    it { is_expected.to validate_presence_of(:product) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:retailer) }
    it { is_expected.to belong_to(:product) }
  end
end
