require 'rails_helper'

RSpec.describe Spree::VariantListing, type: :model do
  subject { build(:spree_variant_listing) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
  end
end
