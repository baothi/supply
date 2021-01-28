module Shopify
  class ProductMetafieldsUpdateWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'shopify_export',
                    backtrace: true,
                    retry: 3

    attr_reader :job, :retailer

    def perform(job_id)
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      return if job.nil?

      job.initialize_and_begin_job! unless job.in_progress?

      products = get_products
      retailers = Spree::Retailer.relies_on_shopify_product_metafields
      process_for_retailers(retailers, products)
      job.complete_job! if job.may_complete_job?
    rescue => e
      puts e.to_s.red
      job.log_error(e.to_s)
      job.raise_issue!
    end

    def get_products
      category_calculator = Spree::Calculator::Shipping::CategoryCalculator.find_by(
        id: job.option_1
      )
      variant_cost = Spree::VariantCost.find_by(id: job.option_2)

      products = []
      products += products_using_this_calculator(category_calculator) if category_calculator
      products += variant_cost.variants.map(&:product) if variant_cost
      products
    end

    def process_for_retailers(retailers, products)
      retailers.each do |retailer|
        begin
          @retailer = retailer
          current_products = products_added_by_retailer(retailer, products)
          process_products(current_products)
        rescue => e
          puts e.to_s.red
          job.log_error(e.to_s)
          job.raise_issue!
        end
      end
    end

    def process_products(products)
      job.update(total_num_of_records: products.size)

      products.each do |product|
        begin
          listing = product.retailer_listing(retailer.id)
          @metafields_master_list ||= product.shopify_metafields(retailer).map { |meta| meta[:key] }

          raise "No listing of product '#{product.name}' found for #{retailer.name}" if listing.nil?

          retailer.init
          shopify_product = ShopifyAPIRetry.retry(3) do
            ShopifyAPI::Product.find(listing.shopify_identifier)
          end

          if shopify_product.blank?
            raise "Shopify product '#{listing.shopify_identifier}' NOT found"
          end

          metafields = ShopifyAPIRetry.retry(3) { shopify_product.metafields }
          missing_keys = update_metafields_value(metafields, product)
          add_missing_metafields(product, shopify_product, missing_keys)
          job.update_status(true)
        rescue => e
          job.log_error(e.message)
          job.raise_issue!
        end
      end
    end

    def products_using_this_calculator(category_calculator)
      category_calculator.calculable.shipping_categories.map(&:products).flatten
    end

    def products_added_by_retailer(retailer, products)
      return retailer.product_listings.includes(:product).map(&:product) if job.option_3 == 'all'

      products.select { |product| product.live?(retailer.id) }
    end

    def update_metafields_value(metafields, product)
      metafields ||= []
      metafield_keys = @metafields_master_list

      metafields.each do |metafield|
        metafield_keys.delete(metafield.key)
        new_value = product.metafield_key_to_value(metafield.key, retailer)
        next if metafield.value == new_value

        metafield.value = new_value
        ShopifyAPIRetry.retry(3) { metafield.save }
      end

      metafield_keys
    end

    def add_missing_metafields(product, shopify_product, keys)
      keys.each do |key|
        metafield = ShopifyAPI::Metafield.new(
          key: key,
          value: product.metafield_key_to_value(key, retailer),
          value_type: 'string',
          namespace: 'hingeto:supplier',
          owner_id: shopify_product.id,
          owner_resource: 'product'
        )

        ShopifyAPIRetry.retry(3) { metafield.save }
      end
    end
  end
end
