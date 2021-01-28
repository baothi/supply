require 'rails_helper'

RSpec.describe CommerceEngine::Shopify::LineItem, type: :service do
  let (:shopify_klass) do
    ShopifyAPI::LineItem
  end

  it_behaves_like 'capable of interacting with shopify'
end
