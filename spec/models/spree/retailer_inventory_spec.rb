require 'rails_helper'

RSpec.describe Spree::RetailerInventory, type: :model do
  subject { build(:spree_retailer_inventory) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:retailer) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:retailer) }
  end
end
