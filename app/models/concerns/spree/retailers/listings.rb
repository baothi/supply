module Spree::Retailers::Listings
  extend ActiveSupport::Concern

  included do
    has_many :variant_listings
    has_many :product_listings
  end

  # Returns list of product IDs associated with all the listings created
  # for the retailer.
  #
  # This requires / assumes that listings are properly created every time
  # products are being added
  def products_ids_for_added_listings
    self.product_listings.pluck(:product_id)
  end

  def listings_for_index(filtering_params)
    products = Spree::Product.by_supplier(self.id)

    filtering_params.each do |key, value|
      # puts "Key: #{key} Value: #{value}".blue
      products = products.public_send(key, value) if value.present?
    end

    puts "#{products.to_sql}".magenta

    puts "Found #{products.count} of products".red

    products
  end

  def update_all_listings_titles!
    self.initialize_shopify_session!
    self.product_listings.each(&:update_shopify_title!)
    self.destroy_shopify_session!
  end

  def listings_missing_on_shopify
    listed_products_shopify_ids = self.product_listings.pluck(:shopify_identifier)
    begin
      self.init
      product_count = ShopifyAPI::Product.count
      number_of_pages = (product_count / 250.0).ceil

      return [] if product_count.zero?

      records = []

      shopify_products = ShopifyAPIRetry.retry do
        ShopifyAPI::Product.find(:all, params: {
            ids: listed_products_shopify_ids.join(','),
            fields: 'id',
            limit: 250
        })
      end

      records += shopify_products

      while shopify_products.next_page?
        shopify_products = shopify_products.fetch_next_page
        records += shopify_products
      end

      missing_identifiers = listed_products_shopify_ids - records.flatten.map(&:id).map(&:to_s)
      self.product_listings.where(shopify_identifier: missing_identifiers)
    rescue => e
      puts e.to_s
      return []
    end
  end

  def create_long_running_job_for_inventory_ingestion
    Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'user',
      retailer_id: self.id
    )
  end

  def ingest_latest_inventory_for_listings_to_store
    begin
      ActiveRecord::Base.transaction do
        job = create_long_running_job_for_inventory_ingestion
        execute_after_commit do
          Shopify::SyndicateInventoryForRetailerWorker.perform_async(job.internal_identifier)
        end
      end
    rescue => ex
      puts "#{ex}".red
      ErrorService.new(exception: ex).perform
    end
  end
end
