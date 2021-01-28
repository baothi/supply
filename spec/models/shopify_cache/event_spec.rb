require 'rails_helper'

RSpec.describe ShopifyCache::Event, type: :model do
  include Mongoid::Matchers

  subject { build(:shopify_cache_event) }

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
    it { is_expected.to have_field(:subject_id).of_type(Integer) }
    it { is_expected.to have_field(:subject_type).of_type(String) }
    it { is_expected.to have_field(:verb).of_type(String) }
    it { is_expected.to have_field(:created_at).of_type(String) }
    it { is_expected.to have_field(:shopify_url).of_type(String) }
    it { is_expected.to have_field(:role).of_type(String) }
  end

  describe 'Indices' do
    it do
      expect(subject).
        to have_index_for(subject_id: 1, subject_type: 1, role: 1, shopify_url: 1).
        with_options(background: true)
    end
  end

  describe 'Associations' do
  end

  context 'Scopes' do
    describe '.processed' do
      it 'returns the correct number of events' do
        create_list(:processed_shopify_cache_event, 3)
        expect(ShopifyCache::Event.processed.count).to eq 3
      end

      it 'returns the correct number of events' do
        create_list(:processed_shopify_cache_event, 2)
        create(:unprocessed_shopify_cache_event)
        expect(ShopifyCache::Event.processed.count).to eq 2
      end
    end

    describe '.unprocessed' do
      it 'returns the correct number of events' do
        create_list(:unprocessed_shopify_cache_event, 2)
        expect(ShopifyCache::Event.unprocessed.count).to eq 2
      end

      it 'returns the correct number of events' do
        create_list(:unprocessed_shopify_cache_event, 3)
        create(:processed_shopify_cache_event)
        expect(ShopifyCache::Event.unprocessed.count).to eq 3
      end
    end
  end

  describe '#mark_as_processed!' do
    let!(:shopify_event) do
      create(:shopify_cache_event,
             shopify_url: spree_supplier.shopify_url)
    end

    it 'marks the product as processed' do
      shopify_event.mark_as_processed!
      expect(shopify_event.processed_at).not_to be_nil
    end
  end

  describe '#mark_as_unprocessed!' do
    let!(:shopify_event) do
      create(:shopify_cache_event,
             shopify_url: spree_supplier.shopify_url,
             processed_at: nil)
    end

    it 'marks the product as processed' do
      shopify_event.mark_as_unprocessed!
      expect(shopify_event.processed_at).to be_nil
    end
  end
end
