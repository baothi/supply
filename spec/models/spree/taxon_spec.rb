require 'rails_helper'

RSpec.describe Spree::Taxon, type: :model do
  it_behaves_like 'a followable model'

  describe 'scope' do
    describe '.is_license' do
      before do
        license_taxonomy = create(:taxonomy, name: 'License')
        create_list(:spree_taxon, 4)
        create_list(:spree_taxon, 2, taxonomy: license_taxonomy)
        @single_license = create(:spree_taxon, taxonomy: license_taxonomy)
      end

      it 'returns 3 taxons' do
        expect(Spree::Taxon.is_license.count).to be 3
      end

      it 'includes the "single_license" in the response' do
        expect(Spree::Taxon.is_license).to include @single_license
      end
    end

    describe '.is_category' do
      before do
        category_taxonomy = create(:taxonomy, name: 'Platform Category')
        create_list(:spree_taxon, 4)
        create_list(:spree_taxon, 2, taxonomy: category_taxonomy)
        @single_category = create(:taxon, taxonomy: category_taxonomy)
      end

      it 'returns 3 taxons' do
        expect(Spree::Taxon.is_category.count).to be 3
      end

      it 'includes the "single_license" in the response' do
        expect(Spree::Taxon.is_category).to include @single_category
      end
    end

    describe '.has_outer_banner' do
      before do
        create_list(:spree_taxon, 4)
        create_list(
          :spree_taxon, 3,
          outer_banner: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
        )
      end

      it 'returns 3 taxons' do
        expect(Spree::Taxon.has_outer_banner.count).to be 3
      end
    end

    describe '.other_licenses_not_in_group' do
      before do
        license_taxonomy = create(:spree_taxonomy, name: 'License')
        create_list(:spree_taxon, 4, taxonomy: license_taxonomy)
        create(:spree_taxon_grouping, taxon: Spree::Taxon.first)
        create(:spree_taxon_grouping, taxon: Spree::Taxon.second)
      end

      xit 'returns 2 taxons' do
        expect(Spree::Taxon.other_licenses_not_in_group.count).to be 2
      end
    end

    describe '#license?' do
      let(:taxon) do
        license_taxonomy = create(:taxonomy, name: 'License')
        create(:spree_taxon, taxonomy: license_taxonomy)
      end

      let(:taxon2) { create(:spree_taxon) }

      it 'returns true for taxon' do
        expect(taxon).to be_license
      end

      it 'returns false for taxon2' do
        expect(taxon2).not_to be_license
      end
    end

    describe '#category?' do
      let(:taxon) do
        category_taxonomy = create(:taxonomy, name: 'Platform Category')
        create(:spree_taxon, taxonomy: category_taxonomy)
      end

      let(:taxon2) { create(:spree_taxon) }

      it 'returns true for taxon' do
        expect(taxon).to be_category
      end

      it 'returns false for taxon2' do
        expect(taxon2).not_to be_category
      end
    end

    describe '#custom_collection?' do
      let(:taxon) do
        custom_collection_taxonomy = create(:taxonomy, name: 'CustomCollection')
        create(:spree_taxon, taxonomy: custom_collection_taxonomy)
      end

      let(:taxon2) { create(:spree_taxon) }

      it 'returns true for taxon' do
        expect(taxon).to be_custom_collection
      end

      it 'returns false for taxon2' do
        expect(taxon2).not_to be_custom_collection
      end
    end
  end
end
