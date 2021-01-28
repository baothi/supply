require 'rails_helper'

RSpec.describe ShopifyCache::Order, type: :model do
  include Mongoid::Matchers

  subject { build(:shopify_cache_order) }

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

  describe 'Indices' do
    it do
      expect(subject).
        to have_index_for(handle: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for(shopify_url: 1, role: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for(fulfillment_status: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for(num_line_items: 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('line_items.sku': 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('billing_address.name': 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('billing_address.address1': 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('shipping_address.name': 1).
        with_options(background: true)
    end

    it do
      expect(subject).
        to have_index_for('shipping_address.address1': 1).
        with_options(background: true)
    end
  end

  describe 'Associations' do
    it { is_expected.to embed_many(:line_items).as_inverse_of(:order) }
  end

  describe '.unfulfilled_orders_at_retailer_store' do
    before do
      # SKU
      @sku = 'TEST-PLATFORM-SKU-RANDOM'

      # Create 5 cached orders
      @shopify_cache_orders = create_list(:shopify_cache_order, 5,
                                          role: 'retailer',
                                          shopify_url: spree_retailer.shopify_url)
      @shopify_cache_orders.each do |cache_order|
        line_item = cache_order.line_items.first
        line_item.update(sku: @sku, quantity: Faker::Number.between(from: 1, to: 10))
      end
    end

    context 'when it comes to case-sensitivity' do
      it 'can deal with downcases' do
        expect(
          ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
            platform_supplier_sku: @sku.downcase,
            retailer: spree_retailer
          )
        ).to eq 5
      end
      it 'can deal with all uppercase' do
        expect(
          ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
            platform_supplier_sku: @sku.upcase,
            retailer: spree_retailer
          )
        ).to eq 5
      end
      it 'can deal with all mixed-case' do
        expect(
          ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
            platform_supplier_sku: @sku.alternate_case,
            retailer: spree_retailer
          )
        ).to eq 5
      end
    end

    it 'returns 0 when retailer is zero' do
      expect(
        ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
          platform_supplier_sku: @sku,
          retailer: nil
        )
      ).to eq 0
    end

    it 'returns the correct number of unfulfilled orders' do
      expect(
        ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
          platform_supplier_sku: @sku,
          retailer: spree_retailer
        )
      ).to eq 5
    end

    it 'returns zero when there are no unfulfilled orders' do
      ShopifyCache::Order.update_all(fulfillment_status: 'fulfilled')
      expect(
        ShopifyCache::Order.num_unfulfilled_orders_at_retailer_store(
          platform_supplier_sku: @sku,
          retailer: spree_retailer
        )
      ).to eq 0
    end
  end

  describe '.quantity_of_items_in_orders_at_retailer_store' do
    before do
      # SKU
      @sku = 'TEST-PLATFORM-SKU-RANDOM'

      # Create 5 cached orders
      @shopify_cache_orders = create_list(:shopify_cache_order, 5,
                                          role: 'retailer',
                                          shopify_url: spree_retailer.shopify_url)
      @shopify_cache_orders.each do |cache_order|
        line_item = cache_order.line_items.first
        line_item.update(sku: @sku, quantity: Faker::Number.between(1, 10))
      end
    end

    it 'returns the correct sum of unfulfilled items' do
      sum = 0
      @shopify_cache_orders.each do |shopify_cache_order|
        shopify_cache_order.line_items.each do |line_item|
          sum += line_item.quantity if
              line_item.sku == @sku
        end
      end

      expect(
        ShopifyCache::Order.quantity_of_items_in_orders_at_retailer_store(
          platform_supplier_sku: @sku,
          retailer: spree_retailer
        )
      ).to eq sum
    end

    it 'returns zero when there are no unfulfilled orders' do
      ShopifyCache::Order.update_all(fulfillment_status: 'fulfilled')
      expect(
        ShopifyCache::Order.quantity_of_items_in_orders_at_retailer_store(
          platform_supplier_sku: @sku,
          retailer: spree_retailer
        )
      ).to eq 0
    end
  end
end
