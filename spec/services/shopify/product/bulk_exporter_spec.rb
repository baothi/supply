require 'rails_helper'

RSpec.describe Shopify::Product::BulkExporter, type: :service do
  describe '#perform' do
    let!(:shopify_export) do
      described_class.new(
        local_products: build_stubbed_list(:spree_product, 2),
        retailer: build_stubbed(:spree_retailer)
      )
    end

    context 'when no products is given' do
      it 'returns nil' do
        shopify_export = described_class.new(
          local_products: [],
          retailer: spree_retailer
        )

        expect(shopify_export.perform).to be_nil
      end
    end

    context 'when products is given' do
      it 'returns a message when there are no missing products on shopify' do
        allow_any_instance_of(described_class).to receive(:missing_products_ids).
          and_return([])

        expect(shopify_export.perform).to eq 'All products exist on your shopify store!'
      end

      it 'returns a message when the export process is completed' do
        allow_any_instance_of(described_class).to receive(:missing_products_ids).
          and_return([1])

        allow_any_instance_of(described_class).to receive(:add_missing_products_to_shopify)

        expect(
          shopify_export.perform
        ).to eq 'All new products have been added to your shopify store'
      end
    end
  end
end
