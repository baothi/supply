require 'spree'
namespace :retailer do
  desc 'Download ghost products'
  task download_ghost_shopify_products: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Looking for products|'
    puts '============================='.magenta

    Spree::Retailer.installed.find_each do |retailer|
      begin
        raise 'Could not connect to shopify' unless
          retailer.initialize_shopify_session!

        ghost_product_listings = []
        ghost_variant_listings = []
        page = 1
        begin
          max_to_import = ENV['MAX_PRODUCTS_TO_IMPORT'].to_i
          count = 0

          products = CommerceEngine::Shopify::Product.find(:all, params: { limit: 250, page: page })

          next if products.nil? || products.empty?

          mxed_products = products.map.select { |product| product.tags.include?('mxed') }

          next if mxed_products.nil?

          page += 1
          mxed_products.each do |product|
            id = product.id
            p_listing = Spree::ProductListing.unscoped.find_by(shopify_identifier: id)
            unless p_listing.present?
              ghost_product_listings << id
            end
            variants = product.variants
            variants.each do |variant|
              v_listing = Spree::VariantListing.unscoped.find_by(shopify_identifier: variant.id)
              unless v_listing.present?
                ghost_variant_listings << variant.id
              end
            end
            count += 1
            break if count >= max_to_import
          end

          next if count >= max_to_import

          sleep 1 if (page % 5).zero?
        end while products&.any?
        puts "#{ghost_product_listings} ghost products for retailer: "\
          "#{retailer.name} - #{retailer.id}".red
        puts "#{ghost_variant_listings} ghost variants for retailer: "\
          "#{retailer.name} - #{retailer.id}".red

        retailer.destroy_shopify_session!
      rescue => ex
        puts "#{ex} for retailer: #{retailer.name} - #{retailer.id}".red
      end
    end
  end

  desc 'Check number of ghost orders'
  task download_ghost_shopify_orders: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Looking for Orders|'
    puts '============================='.magenta

    potential_count = 0
    definitive_count = 0

    Spree::Retailer.installed.find_each do |retailer|
      begin
        raise 'Could not connect to shopify' unless
          retailer.initialize_shopify_session!

        service = Shopify::Audit::GhostOrderAuditor.new(
          retailer: retailer,
          from: Date.today - 21.days,
          to: Date.today + 1.days
        )
        service.perform
        puts "#{service.all_mxed_orders.count}".yellow
        puts "#{service.potential_orders_based_on_sku.count}".yellow

        definitive_count += service.all_mxed_orders.count
        potential_count += service.potential_orders_based_on_sku.count
        retailer.destroy_shopify_session!
      rescue => ex
        puts "#{ex} for retailer: #{retailer.name} - #{retailer.id}".red
      end
    end

    puts "Total Definitive Orders: #{definitive_count}".yellow
    puts "Total Potential Orders: #{potential_count}".yellow
  end

  desc 'Download Orders Information'
  task download_orders_report: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Updating Historical Order Information |'
    puts '============================='.magenta

    Spree::Supplier.find_each do |supplier|
      Spree::Retailer.find_each do |retailer|
        begin
          raise 'Report already generated for today' unless
              retailer.retailer_order_reports.generated_on(DateTime.now).empty?

          last_30_days =  retailer.num_shopify_orders_in_last(30)
          last_60_days =  retailer.num_shopify_orders_in_last(60)
          last_90_days =  retailer.num_shopify_orders_in_last(90)

          report = Spree::RetailerOrderReport.new
          report.source = 'shopify'
          report.supplier = supplier
          report.retailer = retailer
          report.report_generated_at = DateTime.now
          report.num_of_orders_last_30_days = last_30_days
          report.num_of_orders_last_60_days = last_60_days
          report.num_of_orders_last_90_days = last_90_days
          report.save!

          puts "Found: #{last_30_days} - #{last_60_days} - #{last_90_days}"

          retailer.destroy_shopify_session!
        rescue => ex
          puts "#{ex} for retailer: #{retailer.name} - #{retailer.id}".red
        end
      end
    end
  end

  desc 'Download Domain & Plan Information for Retailer'
  task update_plan_and_domain_info: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Downloading Domain & Plan Information |'
    puts '============================='.magenta

    Spree::Retailer.installed.find_each do |retailer|
      begin
        retailer.initialize_shopify_session!

        shopify_store = ShopifyAPI::Shop.current
        retailer.domain = shopify_store.domain
        retailer.plan_name = shopify_store.plan_name
        retailer.plan_display_name = shopify_store.plan_display_name
        retailer.save!

        retailer.destroy_shopify_session!
      rescue => ex
        puts "#{ex} for retailer: #{retailer.name} - #{retailer.id}"
      end
    end
  end

  desc 'Adds Dropshipper specific data to spree_sample data'
  task push_fulfillments: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Sending Fulfillments to Store |'.magenta
    puts '============================='.magenta
    orders = Spree::Order.where('supplier_shopify_identifier is not null').all
    orders.each do |order|
      retailer = order.retailer

      puts "Looking for fulfilled orders not yet sent for #{retailer.name}".yellow

      export_job = Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'orders_export',
        initiated_by: 'system',
        option_1: order.internal_identifier,
        retailer_id: retailer.id
      )
      ShopifyFulfillmentExportJob.perform_later(export_job.internal_identifier)
    end
  end

  desc 'Adds Dropshipper specific data to spree_sample data'
  task create_webhooks: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Creating Retailer Webhooks |'.magenta
    puts '============================='.magenta

    Spree::Retailer.installed.find_each do |retailer|
      puts "Creating for #{retailer.name}".yellow

      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'shopify_import',
        initiated_by: 'user',
        supplier_id: nil,
        retailer_id: retailer.id,
        teamable_type: retailer.class.to_s,
        teamable_id: retailer.id
      )

      Shopify::WebhookCreationJob.perform_now(job.internal_identifier)
      hooks = Spree::Webhook.where(teamable_type: 'Spree::Retailer', teamable_id: retailer.id)
      hooks.each do |hook|
        puts "Hook: #{hook.address}: #{hook.topic}".green
      end

      # Results of Job
      job.reload

      puts job.inspect
    end
  end

  desc 'Remove default/fake variants'
  task remove_default_variants: :environment do
    puts '=============================='.magenta
    puts '| Looking for products|'
    puts '============================='.magenta

    Spree::Retailer.find_each do |retailer|
      Shopify::Audit::DefaultVariantRemover.new(retailer: retailer, from: '2018-01-01').perform
    end
  end

  desc 'set searchable attribues for orders'
  task set_searchable_attributes_field: :environment do
    puts '=============================='.magenta
    puts '| Looking for orders|'
    puts '============================='.magenta

    Spree::Order.find_each(&:set_searchable_attributes)
  end

  desc 'Rename retailers by shopify slug'
  task rename_retailers_to_shopify_slug: :environment do
    puts '==============================================================='.magenta
    puts '|  Renaming all default named retailers to there Shopify name |'
    puts '==============================================================='.magenta

    retailers = Spree::Retailer.where("name iLIKE 'Retailer for%'")
    count = retailers.size
    retailers.find_each(&method(:rename_retailer_if_default_named))

    puts ''
    puts ''
    puts "Done renaming #{count} retailers"
  end

  desc 'Update variants skus with new supplier sku'
  task update_shopify_variant_skus_with_new_supplier_sku: :environment do
    Spree::Retailer.installed.find_each do |retailer|
      Shopify::Audit::VariantSkuUpdater.new(retailer: retailer).perform
    end
  end

  desc 'Update title and description for shopify products'
  task :update_shopify_products_title_description, [:retailer_id] => [:environment] do |_t, args|
    retailer = Spree::Retailer.find_by(args[:retailer_id])
    raise 'Retailer not found' unless retailer.present?

    retailer.init
    listings = retailer.product_listings
    products_hsh = {}
    listings.each { |listing| products_hsh[listing.shopify_identifier] = listing.product }
    shopify_identifiers = listings.map(&:shopify_identifier)
    shopify_identifiers.each_slice(250) do |ids|
      shopify_products = ShopifyAPIRetry.retry(3) do
        ShopifyAPI::Product.find(:all, params: { ids: ids.join(','), limit: 250 })
      end

      shopify_products.each do |shopify_product|
        product = products_hsh[shopify_product.id.to_s]
        shopify_product.body_html = product.description
        ShopifyAPIRetry.retry(3) { shopify_product.save }
      end
    end
  end

  def rename_retailer_if_default_named(retailer)
    return if retailer.shopify_url.nil?

    new_name = retailer.shopify_url.split('.myshopify.com').first.titleize
    retailer.update(name: new_name)
    print '•'.green
  end

  desc 'Update retailer inventory'
  task update_retailer_inventory: :environment do
    Spree::Retailer.find_each do |retailer|
      next unless retailer.setting_enable_15_minute_inventory_updates

      puts "Running for: #{retailer.name}".yellow
      retailer.ingest_latest_inventory_for_listings_to_store
    end
  end

  desc 'Bulk update retailer inventory at store'
  task bulk_update_retailer_inventory: :environment do
    Spree::Retailer.installed.find_each do |retailer|
      puts "Running for: #{retailer.name}".yellow
      retailer.bulk_adjust_inventory_quantities
    end
  end

  desc 'Update shopify products metafield'
  task update_shopify_products_metafields: :environment do
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'system',
      option_3: 'all'
    )

    Shopify::ProductMetafieldsUpdateWorker.perform_async(job.internal_identifier)
  end

  desc 'Create Fulfillment Service'
  task create_fulfillment_service: :environment do
    Spree::Retailer.installed.find_each(&:create_fulfillment_service)
  end

  desc 'Update variant management to hingeto'
  task switch_variant_management_to_hingeto: :environment do
    Spree::Retailer.installed.find_each(&:switch_variant_management_to_hingeto)
  end

  desc 'check for invalid credentials'
  task check_valid_credentials: :environment do
    Spree::Retailer.find_each do |retailer|
      shopify_credential = retailer.shopify_credential
      next unless shopify_credential.present?
      next if shopify_credential.valid_connection?
      next if retailer.app_uninstalled?

      shopify_credential.update(uninstalled_at: Time.now)
    end
  end

  # TODO: Move to background jobs
  desc 'Generate Inventories for valid/installed retailers'
  task generate_inventories_for_retailers: :environment do
    Spree::Retailer.installed.find_each do |retailer|
      begin
        puts "Generating inventory for: #{retailer.id}: #{retailer.name}"
        retailer.generate_inventories!
      rescue => ex
        puts "#{ex}"
        Rollbar.error(ex)
      end
    end
  end

  # Update Order Cache - rake retailer:update_order_cache[60]
  desc 'Update Order Cache'
  task :update_order_cache, %i(num_hours) => [:environment] do |_task, args|
    include CommitWrap
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=========================================='.magenta
    puts '|      Retailer: Updating Order Cache     |'.magenta
    puts '=========================================='.magenta

    num_hours = args[:num_hours].to_i

    Spree::Retailer.installed.find_each do |retailer|
      next unless retailer.shopify_retailer?

      puts "Dealing with #{retailer.id}:#{retailer.domain}".yellow
      retailer.cache_shopify_orders_async!(num_hours: num_hours)
    end
    puts 'Completed!'.green
  end

  desc 'Update product Cache'
  task :update_product_cache, %i(num_hours) => [:environment] do |_task, args|
    include CommitWrap
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    num_hours = args[:num_hours].to_i

    puts "Getting Products updated in the last #{num_hours} hours".yellow

    puts '=========================================='.magenta
    puts '|   Retailer:Updating Product Cache      |'.magenta
    puts '=========================================='.magenta

    Spree::Retailer.installed.find_each do |retailer|
      next unless retailer.shopify_retailer?

      puts "Dealing with #{retailer.id}:#{retailer.domain}".yellow
      retailer.cache_shopify_products_async!(num_hours: num_hours)
    end
    puts 'Completed!'.green
  end

  # TODO: I'm not sure how effecient this is. We may want to
  # look into optimizing how all of this logic is run. We definitely want
  # to move most of the processing into the actual background jobs to avoid
  # lag in the cronjob
  desc 'Run all operational email tasks'
  task operational_emails: :environment do
    Rake::Task['retailer:did_not_installed_app'].invoke
    Rake::Task['retailer:no_sales_with_products'].invoke
    Rake::Task['retailer:did_not_add_product'].invoke
    Rake::Task['retailer:did_not_add_more_than_ten_product'].invoke
  end

  desc 'Retailer signs up via web but hasn’t installed App in 24 hours'
  task did_not_installed_app: :environment do
    last_24_hours = Time.zone.now - (ENV['NOT_INSTALL_IN_24_hour'] || 24).to_i.hour
      installed_email = Spree::Retailer.joins('inner join spree_shopify_credentials ssc on ssc.teamable_id=spree_retailers.id').
      where('ssc.teamable_type = ?','Spree::Retailer').
      pluck(:email)
    retailer_email = Spree::Retailer.where("spree_retailers.created_at < ?",last_24_hours).
      where.not("spree_retailers.unsubscribe @> ?","{did_not_install_app}").
      where("spree_retailers.ecommerce_platform IS NOT NULL").
      distinct.
      pluck(:email)
    non_teamup_email = Spree::Retailer.where.not(app_name: 'teamup').pluck(:email)
    not_installed_email = retailer_email - installed_email - non_teamup_email

    puts '=========================================='.magenta
    puts '|   Retailer:Did Not Install App          |'.magenta
    puts '=========================================='.magenta
    # not_installed_email.each do |email|
    # Spree::Retailer.all.each{|retailer| retailer.update(unsubscribe_hash: SecureRandom.hex)}
    job = Spree::LongRunningJob.create(action_type: 'import',
                                       job_type: 'email_notification',
                                       initiated_by: 'user',
                                       teamable_type: 'Spree::Retailer',
                                       array_option_1: not_installed_email)
    Retailer::DidNotInstallJob.perform_later(job.internal_identifier)
    # end
  end

   # TODO: Move to background jobs
  desc 'Search all retailers that have more than 10 products and have not sold any products in 7 days'
  task no_sales_with_products: :environment do
    last_seven_days = Time.zone.now - (ENV['NOT_SOLD_IN_7_DAYS'] || 7).to_i.days # QC can set to 1
    retailer_ids = Spree::Retailer.joins(:product_listings).
      where.not("spree_retailers.unsubscribe @> ?","{retailer_not_sold_any_products_in_7days}").
      where("spree_retailers.created_at < ?", last_seven_days).
      group(:id).
      having('count(spree_product_listings.retailer_id) >= 10').pluck(:id)
    retailer_not_sold_in_7days =
      Spree::Retailer.
        joins("LEFT JOIN spree_orders so ON so.retailer_id = spree_retailers.id").
        where("so.id IS NULL AND spree_retailers.id IN (?) ", retailer_ids).
        where(app_name: 'teamup').
        pluck(:id)

    for retailer_id in retailer_not_sold_in_7days
      order = Spree::Order.where(retailer_id: retailer_id).count
      if order == 0
        job = Spree::LongRunningJob.create(action_type: 'import',
                                       job_type: 'email_notification',
                                       initiated_by: 'user',
                                       teamable_type: 'Spree::Retailer',
                                       retailer_id: retailer_id)
        Retailer::RetailerNotSoldAnyProductsIn7DaysJob.perform_later(job.internal_identifier)
      end
    end
  end

  # TODO: Move to background jobs
  desc 'search all retailers have been successfully installed but did not add products after 2 days'
  task did_not_add_product: :environment do
    last_two_days = Time.zone.now - (ENV['NOT_ADD_PRODUCT_IN_2_DAYS'] || 2).to_i.days # QC can set to 1

    creds = Spree::ShopifyCredential.where(uninstalled_at: nil).
                                     where(teamable_type: "Spree::Retailer")

    retailer_ids = Spree::Retailer.
      where.not("spree_retailers.unsubscribe @> ?","{did_not_add_product}").
      where('spree_retailers.created_at < ?',last_two_days).
      where(id: creds.pluck(:teamable_id)).
      where(app_name: 'teamup').
      pluck(:id)
    retailer_ids.each do |retailer_id|
      product_listings = Spree::ProductListing.where('spree_product_listings.retailer_id = ?',retailer_id).count
      if product_listings == 0
        job = Spree::LongRunningJob.create(action_type: 'import',
                                       job_type: 'email_notification',
                                       initiated_by: 'user',
                                       teamable_type: 'Spree::Retailer',
                                       retailer_id: retailer_id)
        Retailer::RetailersDidNotAddProductJob.perform_later(job.internal_identifier)
      end
    end
  end

  # TODO: add do not more 10 product
  desc 'search all retailers have been successfully installed but did not add more than 10 product after 5 days'
  task did_not_add_more_than_ten_product: :environment do
    last_five_days = Time.zone.now - (ENV['NOT_ADD_10_PRODUCT_IN_5_DAYS'].to_i || 5).days # QC can set to 1
    retailer_ids = Spree::Retailer
      .joins("inner join spree_shopify_credentials ssc on ssc.teamable_id=spree_retailers.id")
      .where.not("spree_retailers.unsubscribe @> ?","{did_not_add_more_than_ten_product}")
      .where('ssc.teamable_type = ?','Spree::Retailer')
      .where("spree_retailers.created_at < ?",last_five_days)
      .where(app_name: 'teamup')
      .pluck(:id)
    retailer_ids.each do |retailer_id|
      product_listings = Spree::ProductListing.where('spree_product_listings.retailer_id = ?',retailer_id).count
      unless product_listings >= 10 || product_listings < 1
        job = Spree::LongRunningJob.create(action_type: 'import',
                                       job_type: 'email_notification',
                                       initiated_by: 'user',
                                       teamable_type: 'Spree::Retailer',
                                       retailer_id: retailer_id)
        Retailer::DidNotAddMoreThanTenProductJob.perform_later(job.internal_identifier)
      end
    end
  end

end
