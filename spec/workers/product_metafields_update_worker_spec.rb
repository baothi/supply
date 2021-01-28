require 'rails_helper'

RSpec.describe Shopify::ProductMetafieldsUpdateWorker, type: :worker do
  let(:retailers) { create_list(:spree_retailer, 2) }
  let(:retailer1) { retailers.first }
  let(:retailer2) { retailers.last }
  let(:products) { create_list(:spree_product, 5) }
  let(:products1) { create_list(:spree_product, 3) }
  let(:products2) { create_list(:spree_product, 2) }

  describe 'process_for_retailers' do
    subject { described_class.new }

    it 'calls process_products with right arguments' do
      allow(subject).to receive(:process_products).and_return true

      expect(subject).to receive(:products_added_by_retailer).
        with(retailer1, products).and_return(products1)
      expect(subject).to receive(:products_added_by_retailer).
        with(retailer2, products).and_return(products2)

      subject.process_for_retailers(retailers, products)
    end
  end
end
