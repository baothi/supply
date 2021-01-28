require 'rails_helper'

describe Spree::QueryBuilder::Search do
  describe '.like' do
    it 'returns a SQL string with a single iLIKE and wildcard placeholder' do
      expect(described_class.like(:orders, :number)).to eq 'spree_orders.number iLIKE :wildcard '
    end
  end

  describe '.composite_like' do
    it 'returns a SQL string with several iLIKEs and wildcard placeholder' do
      joins = { variants: %i(sku id), products: [:description], orders: [:number], foo: nil }

      result = ['spree_variants.sku iLIKE :wildcard OR ', 'spree_variants.id iLIKE :wildcard OR ',
                'spree_products.description iLIKE :wildcard OR ',
                'spree_orders.number iLIKE :wildcard '].join

      expect(described_class.composite_like(joins)).to eq result
    end
  end

  describe '.wildcard' do
    it 'returns a wildcard string' do
      expect(described_class.wildcard('123')).to eq '%123%'
    end
  end
end
