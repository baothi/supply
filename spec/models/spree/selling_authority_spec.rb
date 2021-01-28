require 'rails_helper'

RSpec.describe Spree::SellingAuthority, type: :model do
  subject { build :spree_selling_authority }

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_selling_authority, retailer: nil)).not_to be_valid }
      it { expect(build(:spree_selling_authority, permittable: nil)).not_to be_valid }
      it { expect(build(:spree_selling_authority, permission: nil)).not_to be_valid }
    end
  end

  describe 'Model Associations' do
    it { is_expected.to belong_to(:retailer) }
    it { is_expected.to belong_to(:permittable) }
  end

  describe 'validations' do
    let(:retailer) { create(:spree_retailer) }
    let(:supplier) { create(:spree_supplier) }

    before { create(:spree_selling_authority, retailer: retailer, permittable: supplier) }

    it 'validates permittable uniqueness accross retailer' do
      expect { create(:spree_selling_authority, retailer: retailer, permittable: supplier) }.
        to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'Model collbacks' do
    it { is_expected.to callback(:set_permittable).before(:validation) }

    describe '#set_permittable' do
      subject do
        build :spree_selling_authority,
              permittable: nil,
              permittable_string: "Spree::Product #{product.id}"
      end

      let(:product) do
        create :spree_product
      end

      it { is_expected.to be_valid }
      it 'sets permittable after validation' do
        expect(subject.permittable).to be_nil
        subject.validate
        expect(subject.permittable).to eql product
      end
    end
  end

  describe '.current_permittable_opts' do
    before { subject.save }

    it { expect(Spree::SellingAuthority.current_permittable_opts(subject.id)).to be_a Hash }
    it { expect(Spree::SellingAuthority.current_permittable_opts(subject.id)).to have_key :text }
    it { expect(Spree::SellingAuthority.current_permittable_opts(subject.id)).to have_key :id }
    it do
      expect(Spree::SellingAuthority.current_permittable_opts(subject.id)).
        to have_value subject.permittable.name
    end

    it do
      expect(Spree::SellingAuthority.current_permittable_opts(subject.id)).
        to have_value subject.permittable_getter
    end
  end

  describe '.permittable_opts' do
    it { expect(Spree::SellingAuthority.permittable_opts('query')).to be_a Hash }
    it { expect(Spree::SellingAuthority.permittable_opts('query')).to have_key :results }
  end
end
