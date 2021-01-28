module ShopifyTopics
  extend RSpec::SharedContext

  # Orders
  let(:shopify_orders_created_topic) do
    'orders/create'
  end

  let(:shopify_orders_updated_topic) do
    'orders/updated'
  end

  let(:shopify_orders_fulfilled_topic) do
    'orders/fulfilled'
  end

  let(:shopify_orders_partially_fulfilled_topic) do
    'orders/partially_fulfilled'
  end

  # Products
  let(:shopify_products_created_topic) do
    'products/create'
  end

  let(:shopify_products_updated_topic) do
    'products/update'
  end

  let(:shopify_products_deleted_topic) do
    'products/delete'
  end

  # Fulfillments
  let(:shopify_fulfillments_create_topic) do
    'fulfillments/create'
  end

  let(:shopify_fulfillments_updated_topic) do
    'fulfillments/update'
  end

  let(:shopify_app_uninstalled_topic) do
    'app/uninstalled'
  end

  # Headers

  let!(:shopify_orders_created_header) do
    { 'HTTP_X_SHOPIFY_TOPIC' => shopify_orders_created_topic }
  end
end
