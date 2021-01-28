require 'rails_helper'

RSpec.describe ShopifyCache::Variant, type: :model do
  include Mongoid::Matchers

  subject { build(:shopify_cache_variant) }

  before do
    Mongoid.purge!
  end

  describe 'Model from Factory' do
    it { is_expected.to be_mongoid_document }
    it { is_expected.to be_dynamic_document }
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:shopify_url) }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe 'Fields' do
    it { is_expected.to have_field(:title).of_type(String) }
    it { is_expected.to have_field(:price).of_type(String) }
    it { is_expected.to have_field(:sku).of_type(String) }
    it { is_expected.to have_field(:inventory_policy).of_type(String) }
    it { is_expected.to have_field(:fulfillment_service).of_type(String) }
    it { is_expected.to have_field(:inventory_management).of_type(String) }
    it { is_expected.to have_field(:option1).of_type(String) }
    it { is_expected.to have_field(:option2).of_type(String) }
    it { is_expected.to have_field(:option3).of_type(String) }
    it { is_expected.to have_field(:lower_sku).of_type(String) }
    it { is_expected.to have_field(:lower_barcode).of_type(String) }
    it { is_expected.to have_field(:shopify_url).of_type(String) }
    it { is_expected.to have_field(:role).of_type(String) }

  end

  describe 'Indices' do
    it do
      expect(subject).
        to have_index_for(lower_sku: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
          to have_index_for(lower_barcode: 1).
              with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for(lower_sku: 1, product_id: 1).
        with_options(background: true)
      end

    it do
      expect(subject).
        to have_index_for(lower_sku: 1, product_id: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
          to have_index_for(role: 1, shopify_url: 1, lower_sku:1, created_at: -1).
              with_options(background: true)
    end
  end



end
