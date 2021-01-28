require 'rails_helper'

describe 'Spree::Search' do
  describe '#like' do
    it 'returns and ActiveRecord::Relation instance' do
      product = create(:product)
      result = Spree::Search.new(keyword: product.description.slice(0..2),
                                 relation: Spree::Product.all,
                                 joins: { products: [:description],
                                          variants: [:sku] }).like

      expect(result.class).to eq Spree::Product::ActiveRecord_Relation
      expect(result.size.positive?).to be true
    end

    it 'returns the order that matched the search critieria' do
      order = create(:order, user: create(:spree_user, last_name: 'Foo', first_name: 'Bar'))
      result = Spree::Search.new(keyword: order.number.slice(0..2),
                                 relation: Spree::Order.all,
                                 joins: { orders: [:number] }).like

      expect(result.size.positive?).to be true
    end

    it 'returns the sample order that matched the search critieria' do
      sample = create(:order,
                      user: create(:spree_user, last_name: 'Foo', first_name: 'Bar'),
                      retailer: spree_retailer,
                      supplier: spree_supplier,
                      source: 'app',
                      state: 'complete',
                      completed_at: DateTime.now,
                      variants: create_list(:variant, 2))
      result = Spree::Search.new(keyword: sample.number.slice(0..2),
                                 relation: Spree::Order.all,
                                 joins: { orders: [:number] }).like
      expect(result.size.positive?).to be true
    end
  end
end
