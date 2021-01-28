# For syncing all supplier products
class Shopify::BulkProductImportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CommitWrap
  include CancellableJob

  sidekiq_options queue: 'shopify_import',
                  backtrace: true

  attr_reader :custom_params, :options

  def perform(job_id, options = {})
    begin
      @options = options
      return if cancelled?

      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      supplier = Spree::Supplier.find(job.supplier_id)
      supplier.init
      @custom_params = JSON.parse(job.option_3 || '{}')
      puts @custom_params.inspect
      # First get all the products into a local hash
      num_pages = pages
      shopify_products = retrieve_products(num_pages)

      # Create Sidekiq batch
      batch_jobs(job, supplier, shopify_products, num_pages)
    rescue => ex
      puts "#{ex}".red
      Rollbar.error(ex, job_id: job_id)
    end
  end

  def retrieve_products(num_pages)
    products = {}
    shopify_products = ShopifyAPIRetry.retry do
      ShopifyAPI::Product.find(:all, params: { limit: PER_PAGE.to_i }.merge(custom_params))
    end

    products[1] = shopify_products

    (2..num_pages).each do |page|
      return if cancelled?
      break unless shopify_products.next_page?

      shopify_products = shopify_products.fetch_next_page

      products[page] = shopify_products
    end
    products
  end

  def batch_jobs(job, supplier, shopify_products, num_pages)
    batch = Sidekiq::Batch.new
    batch.description = "Import for Supplier: #{supplier.name}"
    batch.on(:success, BulkImportJobCompletion,
             num_pages: num_pages,
             supplier_id: supplier.id,
             supplier_name: supplier.name,
             send_email: job.option_2)
    batch.on(:complete, BulkImportJobCompletion,
             num_pages: num_pages,
             supplier_id: supplier.id,
             supplier_name: supplier.name,
             send_email: job.option_2)
    batch.jobs do
      shopify_products.values.each do |page|
        opts = {}
        opts['supplier_id'] = supplier.id
        opts['shopify_products'] = page.to_json
        create_and_queue_long_running_job(opts, job)
      end
    end
  end

  def create_and_queue_long_running_job(opts, outer_job)
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        option_1: opts['shopify_products'],
        option_2: outer_job.option_2,
        supplier_id: opts['supplier_id']
      )
      execute_after_commit do
        if options[:run_sync]
          Shopify::ProcessShopifyProductsWorker.new.perform(job.internal_identifier, run_sync: true)
        else
          Shopify::ProcessShopifyProductsWorker.perform_async(job.internal_identifier)
        end
      end
    end
  end

  class BulkImportJobCompletion
    include Emailable

    def on_complete(status, options)
      puts 'Uh oh, batch has failures'.yellow if status.failures != 0
      return if options['send_email'] == 'no'

      num_products =
        Spree::Supplier.find(options['supplier_id']).num_recently_created_products
      subject = "[Product Sync] #{options['supplier_name']} completed"
      body = I18n.t('products.shopify.product_import_job_completion',
                    supplier: options['supplier_name'],
                    num_products: num_products,
                    num_issues: status.failures)
      email_results_to_operations!(subject, body)
    end

    def on_success(_status, options)
      puts "#{options['supplier_name']}'s batch succeeded.  Kudos!".green
    end
  end

  private

  PER_PAGE = 250.to_f

  def pages
    ShopifyAPIRetry.retry do
      (ShopifyAPI::Product.count(custom_params) / PER_PAGE).ceil
    end
  end
end
