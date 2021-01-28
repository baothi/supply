require 'rails_helper'

RSpec.describe Spree::ProductListing, type: :model do
  subject { build(:spree_product_listing) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:shopify_identifier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:retailer) }
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:supplier) }
  end
end
