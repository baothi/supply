require 'rails_helper'

RSpec.describe Spree::ShopifyCredential, type: :model do
  subject { build(:spree_shopify_credential) }

  # TODO Include Shared Test for Generation of Internal Identifier

  describe 'Factory' do
    it { is_expected.to be_valid }

    context 'when there is no valid association' do
      it { expect(build(:spree_shopify_credential, teamable: nil)).not_to be_valid }
      it { expect(build(:spree_shopify_credential, store_url: nil)).not_to be_valid }
    end
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:teamable) }
  end

  describe 'Active model validations' do
    it { is_expected.to validate_presence_of(:teamable) }
    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_presence_of(:store_url) }
  end

  describe '#disable_connection!' do
    let(:supplier) { create(:spree_supplier) }
    let(:credential) { create(:spree_shopify_credential, teamable: supplier) }

    it 'sets uninstall_at for shopify credential' do
      expect { credential.disable_connection! }.
        to change { credential.reload.uninstalled_at }.from(nil)
    end

    context 'supplier' do
      let(:variant) { create(:spree_variant, supplier: supplier) }

      it 'discontinues supplier products and variants' do
        expect(variant.discontinue_on).to be nil

        credential.disable_connection!

        expect(variant.reload.discontinue_on).not_to be nil
      end
    end
  end
end
