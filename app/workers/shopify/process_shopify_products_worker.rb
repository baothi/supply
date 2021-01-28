class Shopify::ProcessShopifyProductsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'shopify_import',
                  backtrace: true

  def perform(job_id, options = {})
    begin
      @options = options
      return if cancelled?

      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      supplier_id = job.supplier_id
      shopify_products = JSON.parse(job.option_1, object_class: OpenStruct)

      raise 'Supplier ID is needed' if supplier_id.nil?
      raise 'Shopify Products Required' if shopify_products.nil?

      # Iterate through products
      iterate_and_import_shopify_products(shopify_products, supplier_id, job)

      job.complete_job!
    rescue => ex
      puts ex.to_s.red
      puts ex.backtrace.to_s.red
      Rollbar.error(ex, job_id: job_id)
    end
  end

  def iterate_and_import_shopify_products(shopify_products, supplier_id, job)
    shopify_products.each_with_index do |shopify_product, index|
      begin
        break if index > ENV['MAX_PRODUCTS_TO_IMPORT'].to_i
        break if cancelled?

        puts "Looking to import: #{shopify_product.id}".yellow
        t1 = Time.now
        puts "Start Time: #{t1}"
        importer = Shopify::Product::Importer.new(
          supplier_id: supplier_id, run_sync: @options[:run_sync], download_images: job.option_2
        )
        importer.perform(shopify_product)
        t2 = Time.now
        puts "Total Time to Import: #{shopify_product.id}: #{(t2 - t1)}".blue
      rescue => ex
        puts ex.to_s.red
        puts ex.backtrace.to_s.red
      end
    end
  end
end
