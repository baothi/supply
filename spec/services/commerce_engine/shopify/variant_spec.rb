require 'rails_helper'

RSpec.describe CommerceEngine::Shopify::Variant, type: :service do
  let (:shopify_klass) do
    ShopifyAPI::Variant
  end

  it_behaves_like 'capable of interacting with shopify'
end
