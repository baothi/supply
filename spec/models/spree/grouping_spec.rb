require 'rails_helper'

RSpec.describe Spree::Grouping, type: :model do
  subject { build(:spree_grouping) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_grouping, name: nil)).not_to be_valid }
      it { expect(build(:spree_grouping, group_type: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:group_type) }

    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'Active model associations' do
    it { is_expected.to have_many(:taxon_groupings) }
    it { is_expected.to have_many(:taxons).through(:taxon_groupings) }
  end
end
