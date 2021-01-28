require 'rails_helper'

RSpec.describe CommerceEngine::Shopify::Generic, type: :service do
  let (:subject) do
    CommerceEngine::Shopify::Generic
  end

  describe '.corresponding_shopify_commerce_engine' do
    it 'return product' do
      expect(subject.corresponding_shopify_commerce_engine('ShopifyAPI::Product')).
        to eq CommerceEngine::Shopify::Product
    end

    it 'return variant' do
      expect(subject.corresponding_shopify_commerce_engine('ShopifyAPI::Variant')).
        to eq CommerceEngine::Shopify::Variant
    end

    it 'return order' do
      expect(subject.corresponding_shopify_commerce_engine('ShopifyAPI::Order')).
        to eq CommerceEngine::Shopify::Order
    end
  end
end
