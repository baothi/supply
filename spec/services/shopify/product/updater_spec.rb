require 'rails_helper'

RSpec.describe Shopify::Product::Updater, type: :service do
  before do
    @supplier = spree_supplier
    @shopify_product = load_fixture('shopify/product')
    allow(ShopifyAPI::Product).to receive(:find).and_return(@shopify_product)
    local_variants = product.variants

    shopify_variants = @shopify_product.variants
    shopify_variants.each_with_index do |sv, i|
      local_variants[i].update(shopify_identifier: sv.id)
    end
  end

  let (:subject) do
    Shopify::Product::Updater.new(
      supplier_id: product.supplier_id
    )
  end

  let(:product) do
    create(:spree_product_in_stock, shopify_identifier: @shopify_product.id, description: nil)
  end

  describe '#perform' do
    it 'updates product description' do
      subject.perform(product.shopify_identifier)
      expect(product.reload.description).to eq @shopify_product.body_html
    end

    it 'updates product price' do
      subject.perform(product.shopify_identifier)
      expect(product.reload.price).to eq @shopify_product.variants.first.price.to_f * 1.07
    end

    it 'updates product publishable status' do
      product.discontinue!

      subject.perform(product.shopify_identifier)
      expect(product.reload.discontinued?).to eq false
    end
  end

  describe '#update_variant_stock' do
    it 'updates variant stock' do
      shopify_variant = @shopify_product.variants.sample
      variant = Spree::Variant.find_by(shopify_identifier:  shopify_variant.shopify_identifier)

      subject.update_variant_stock(variant, shopify_variant)
      expect(variant.reload.count_on_hand).to eq shopify_variant.inventory_quantity
    end
  end

  describe '#update_variant_price' do
    it 'updates variant price' do
      shopify_variant = @shopify_product.variants.sample
      variant = Spree::Variant.find_by(shopify_identifier:  shopify_variant.shopify_identifier)

      subject.update_variant_price(variant, shopify_variant)
      expect(variant.reload.price).to eq shopify_variant.price.to_f * 1.07
    end
  end
end
