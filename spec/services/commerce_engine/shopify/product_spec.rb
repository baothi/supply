require 'rails_helper'

RSpec.describe CommerceEngine::Shopify::Product, type: :service do
  let (:shopify_klass) do
    ShopifyAPI::Product
  end

  it_behaves_like 'capable of interacting with shopify'
end
