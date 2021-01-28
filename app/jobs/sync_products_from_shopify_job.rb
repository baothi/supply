class SyncProductsFromShopifyJob < ApplicationJob
  queue_as :shopify_import

  def perform(job_id)
    LegacyShopify::Product.sync_all(job_id)
  end
end
