require 'rails_helper'

RSpec.describe Spree::TaxonGrouping, type: :model do
  subject { build(:spree_taxon_grouping) }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_taxon_grouping, taxon: nil)).not_to be_valid }
      it { expect(build(:spree_taxon_grouping, grouping: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:taxon) }
    it { is_expected.to validate_presence_of(:grouping) }

    it do
      expect(subject).to validate_uniqueness_of(:taxon).scoped_to(:grouping_id).
        with_message('already exists in this grouping')
    end
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:taxon) }
    it { is_expected.to belong_to(:grouping) }
  end
end
