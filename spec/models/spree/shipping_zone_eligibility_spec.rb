require 'rails_helper'

RSpec.describe Spree::ShippingZoneEligibility, type: :model do
  subject { build(:spree_shipping_zone_eligibility) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:zone) }
    it { is_expected.to validate_presence_of(:supplier) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:zone) }
    it { is_expected.to belong_to(:supplier) }
  end
end
