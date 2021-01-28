require 'spree'

namespace :supplier do
  desc 'Create Supplier Options & Respective Shipping Options'
  task generate_categories: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '====================================================='.magenta
    puts '| Generating Supplier Category Options for Suppliers |'.magenta
    puts '====================================================='.magenta

    Spree::Supplier.find_each do |supplier|
      puts "Working with #{supplier.id}:#{supplier.domain}".yellow
    end

    puts 'Completed!'.green
  end

  desc 'Adds Dropshipper specific data to spree_sample data'
  task create_webhooks: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=============================='.magenta
    puts '| Creating Supplier Webhooks |'.magenta
    puts '============================='.magenta

    Spree::Supplier.installed.find_each do |supplier|
      puts "Dealing with #{supplier.id}:#{supplier.domain}".yellow

      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'shopify_import',
        initiated_by: 'user',
        teamable_type: 'Spree::Supplier',
        teamable_id: supplier.id
      )

      Shopify::WebhookCreationJob.perform_now(job.internal_identifier)

      # Results of Job
      job.reload

      puts job.inspect

      # Now show webhooks

      hooks = Spree::Webhook.where(teamable_type: 'Spree::Supplier', teamable_id: supplier.id)
      hooks.each do |hook|
        puts "Hook: #{hook.address}: #{hook.topic}".green
      end

      ShopifyAPI::Webhook.all.each do |hook|
        puts "[Shopify] Hook: #{hook.address}: #{hook.topic}".magenta
      end
    end
  end

  desc 'Update Inventory & Visibility'
  task :update_inventory_and_visibility,
       %i(min_product_count max_product_count) => [:environment] do |_task, args|
    include CommitWrap

    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    if args[:max_product_count].to_i <= args[:min_product_count].to_i
      puts 'Invalid parameters!'.red
      next
    end

    puts '=========================================='.magenta
    puts '| Updating Product Visiblity & inventory |'.magenta
    puts '=========================================='.magenta

    Spree::Supplier.installed.find_each do |supplier|
      puts "Dealing with #{supplier.id}:#{supplier.domain}".yellow
      begin
        product_count = supplier.products.count
        next if product_count.zero?

        unless (args[:min_product_count].to_i..args[:max_product_count].to_i).cover?(product_count)
          puts "#{supplier.name}'s number of products #{product_count} "\
            'is not in range. Skipping'.red
          next
        end

        ActiveRecord::Base.transaction do
          job = Spree::LongRunningJob.create(
            action_type: 'import',
            job_type: 'products_import',
            initiated_by: 'user',
            option_1: 'mass',
            option_2: 'no', # Send Email?
            supplier_id: supplier.id,
            teamable_type: 'Spree::Supplier',
            teamable_id: supplier.id
          )

          execute_after_commit do
            Shopify::BulkProductImportWorker.perform_async(job.internal_identifier)
            puts "Successfully queued for #{supplier.id}:#{supplier.domain}".green
          end
        end
      rescue => ex
        puts "#{ex}".red
      end
    end

    puts 'Completed!'.green
  end

  def generate_shipping_category!(category_name, supplier)
    raise 'Supplier is required to proceed with non-default categories' if
        supplier.nil? && category_name != 'Default'

    if supplier.nil? || category_name == 'Default'
      unique_category_name = "#{category_name}"
      shipping_category = Spree::ShippingCategory.where(
        name: unique_category_name
      ).first_or_create!
    elsif supplier.present?
      unique_category_name = "[#{supplier.name}] - #{category_name}"
      shipping_category = Spree::ShippingCategory.where(
        name: unique_category_name,
        supplier: supplier
      ).first_or_create!
    else
      raise 'Odd scenario encountered while generating shipping category'
    end
    [shipping_category, unique_category_name]
  end

  def create_shipping_method_and_category(category_name, supplier)
    zone = Spree::Zone.find_by_name('United States')
    raise 'United States zone is required to proceed' if zone.nil?

    results = generate_shipping_category!(category_name, supplier)
    shipping_category = results[0]
    unique_category_name = results[1]

    Spree::ShippingMethod.where(name: unique_category_name).first_or_create! do |shipping_method|
      code = category_name.gsub(/\s+/, '').upcase
      shipping_method.admin_name = code
      shipping_method.code = code
      calculator = Spree::Calculator::Shipping::CategoryCalculator.new
      calculator.set_preference(:first_item_us, 5)
      calculator.set_preference(:additional_item_us, 2)
      shipping_method.calculator = calculator
      shipping_method.shipping_categories << shipping_category
      shipping_method.zones << zone
      shipping_method.supplier = supplier unless supplier.nil?
    end

    shipping_category
  end

  def create_default_category!
    create_shipping_method_and_category('Default', nil)
  end

  desc 'Create shipping methods'
  task create_shipping_methods: :environment do
    # Spree::ShippingMethodCategory.destroy_all
    # Spree::ShippingCategory.destroy_all
    # Spree::ShippingMethod.destroy_all
    # Spree::ShippingMethodZone.destroy_all
    puts 'Creating Shipping Methods and Stuff'.yellow
    Spree::Supplier.find_each do |supplier|
      product_categories = Spree::Product.
                           by_supplier(supplier.id).
                           pluck(:shopify_product_type).uniq

      puts 'product_categories cannot be nil'.red if product_categories.empty?
      product_categories.reject!(&:blank?)

      next if product_categories.empty?

      puts "Proceeding with #{product_categories}".yellow

      # Create Shipping Categories for each type of product
      product_categories.each do |product_type|
        puts 'Product Type cannot be nil'.red if product_type.blank?
        next if product_type.blank?

        shipping_category = create_shipping_method_and_category(product_type, supplier)

        # Now find all the products
        Spree::Product.where(
          'shopify_product_type = :shopify_product_type and supplier_id = :supplier_id',
          supplier_id: supplier.id,
          shopify_product_type:  product_type
        ).find_each do |product|
          product.update(shipping_category_id: shipping_category.id)
        end
      end
    end

    # Deal with the stragglers
    default = create_default_category!

    Spree::Product.where('shopify_product_type is null').find_each do |product|
      product.update(shipping_category_id: default.id)
    end

    puts 'Completed Creating Shipping Methods and Stuff'.green
  end

  # Temporary Rake Task
  desc 'Update all current shipping categories & methods to be the first supplier'\
    'that we had int he platform'
  task update_supplier_categories_bioworld: :environment do
    supplier = Spree::Supplier.first

    Spree::ShippingCategory.find_each do |shipping_category|
      next if shipping_category.name == 'Default'

      category_name = "[#{supplier.name}] - #{shipping_category.name}"
      shipping_category.update(
        supplier_id: supplier.id,
        name: category_name
      )
    end

    Spree::ShippingMethod.find_each do |shipping_method|
      next if shipping_method.name == 'Default'

      shipping_method_name = "[#{supplier.name}] - #{shipping_method.name}"
      shipping_method.update(
        supplier_id: supplier.id,
        name: shipping_method_name
      )
    end
    puts 'Completed!'.green
  end

  desc 'Update all shipping methods to use USA instead of North America'
  task update_all_shipping_zones_to_usa_only: :environment do
    zone = Spree::Zone.find_by_name('United States')
    raise 'United States zone is required to proceed' if zone.nil?

    Spree::ShippingMethod.find_each do |shipping_method|
      shipping_method.zones.destroy_all
      shipping_method.zones << zone
      shipping_method.save
    end
    puts 'Completed!'.green
  end

  desc 'Update all Products to be approved - should only be used once'
  task approve_all_products: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('in_production').red
    end

    puts 'Which supplier would you like to approve all products for?'.blue
    Spree::Supplier.find_each do |supplier|
      puts "[#{supplier.id}] - #{supplier.name}".yellow
    end
    supplier_id = Dropshipper::CommandLineHelper.get_input
    supplier_id = supplier_id.to_i
    puts 'Ok great. Proceeding with approving all products for '\
      "#{Spree::Supplier.find(supplier_id).name}".yellow

    puts 'Are you sure you want to proceed y[es] or n[o]'.blue
    confirmation = Dropshipper::CommandLineHelper.get_input

    if confirmation == 'y'
      Spree::Product.by_supplier(supplier_id).
        where(submission_state: [nil, '']).
        update_all(submission_state: 'approved')
      puts I18n.t('successfully_approved_products').green
    else
      puts I18n.t('no_products_approved').yellow
    end
  end

  desc 'Update all Products to be rejected - should rarely be used once'
  task reject_all_products: :environment do
    if Hingeto::Dropshipper.dangerous_environment?
      puts I18n.t('in_production').red
    end

    puts 'Which supplier would you like to reject all products for?'.blue
    Spree::Supplier.find_each do |supplier|
      puts "[#{supplier.id}] - #{supplier.name}".yellow
    end
    supplier_id = Dropshipper::CommandLineHelper.get_input
    supplier_id = supplier_id.to_i
    puts 'Ok great. Proceeding with approving all products for '\
      "#{Spree::Supplier.find(supplier_id).name}".yellow

    puts 'Are you sure you want to proceed y[es] or n[o]'.blue
    confirmation = Dropshipper::CommandLineHelper.get_input

    if confirmation == 'y'
      Spree::Product.by_supplier(supplier_id).
        where(submission_state: [nil, '']).
        update_all(submission_state: 'declined')
      puts I18n.t('successfully_declined_products').green
    else
      puts I18n.t('no_products_declined').yellow
    end
  end

  desc 'Copy skus to original supplier sku'
  task copy_skus_to_original_supplier_sku: :environment do
    Spree::Supplier.find_each do |supplier|
      if supplier.brand_short_code.blank?
        puts "brand short code has not been set for Supplier #{supplier.name}".yellow
        next unless supplier.set_brand_short_code

        puts "successfully set brand short code for #{supplier.name}".green
      end
      supplier.variants.find_each do |variant|
        next if variant.original_supplier_sku.blank?

        platform_supplier_sku = variant.generate_platform_sku
        variant.update_columns(
          platform_supplier_sku: platform_supplier_sku
        )
      end
    end
  end

  desc 'Download DSCO fulfillments'
  task download_dsco_fulfillments: :environment do
    sftp = Net::SFTP.start(
      ENV['DSCO_FTP_HOST'],
      ENV['DSCO_FTP_USER'],
      password: ENV['DSCO_FTP_PASSWORD']
    )

    shipment_files = sftp.dir.glob('/out', 'Order_Shipment_*.csv')

    shipment_files.each do |shipment_file|
      contents = sftp.file.open("out/#{shipment_file.name}").read

      tmpfile = Tempfile.new([shipment_file.name.split('.')[0], '.csv'])
      tmpfile.binmode
      tmpfile.write(contents)
      tmpfile.rewind

      job = Spree::LongRunningJob.new(
        action_type: 'import',
        job_type: 'fulfillments_import',
        initiated_by: 'system',
        input_csv_file: tmpfile
      )
      if job.save
        Dsco::Fulfillment::BatchImportJob.perform_later(job.internal_identifier)
        sftp.rename!("out/#{shipment_file.name}", "out/archive/#{shipment_file.name}")
      end
    end
  end

  desc 'Update Supplier orders shopify identifiers'
  task update_order_shopify_identifiers: :environment do
    Spree::Supplier.installed.find_each do |supplier|
      begin
        supplier.initialize_shopify_session!

        supplier.orders.find_in_batches(batch_size: 250) do |local_orders|
          next if local_orders.empty?

          shopify_ids = local_orders.pluck(:supplier_shopify_identifier)
          next if shopify_ids.compact.empty?

          local_orders_map = local_orders.group_by(&:supplier_shopify_identifier)
          shopify_orders = ShopifyAPIRetry.retry(3) do
            ShopifyAPI::Order.find(:all, params: { ids: shopify_ids.join(','), limit: 250 })
          end
          shopify_orders.each do |shopify_order|
            local_order = local_orders_map[shopify_order.id.to_s].first
            local_order.supplier_shopify_order_number = shopify_order.order_number
            local_order.supplier_shopify_number = shopify_order.number
            local_order.supplier_shopify_order_name = shopify_order.name
            local_order.shopify_sent_at = shopify_order.created_at
            local_order.save!
          end
          puts 'Update supplier shopify identifiers colums successfully'.green
        end
      rescue => ex
        puts 'Error occured while setting supplier identifiers'.red
        puts "Supplier Name is #{supplier.name}"
        puts "Error!! #{ex}".red
        puts ex.backtrace
      end

      supplier.destroy_shopify_session!
    end
  end

  desc 'check for invalid credentials'
  task check_valid_credentials: :environment do
    Spree::Supplier.find_each do |supplier|
      shopify_credential = supplier.shopify_credential
      next unless shopify_credential.present?
      next if shopify_credential.valid_connection?
      next if supplier.app_uninstalled?

      shopify_credential.update(uninstalled_at: Time.now)
    end
  end

  # Update Order Cache - rake supplier:update_order_cache[60]
  desc 'Update Order Cache'
  task :update_order_cache, %i(num_hours) => [:environment] do |_task, args|
    include CommitWrap
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=========================================='.magenta
    puts '|       Updating Order Cache             |'.magenta
    puts '=========================================='.magenta

    num_hours = args[:num_hours].to_i

    Spree::Supplier.installed.find_each do |supplier|
      next unless supplier.shopify_supplier?

      puts "Dealing with #{supplier.id}:#{supplier.domain}".yellow
      supplier.cache_shopify_orders_async!(num_hours: num_hours)
    end
    puts 'Completed!'.green
  end

  # Update Product Cache - rake supplier:update_product_cache[60]
  desc 'Update product Cache'
  task :update_product_cache, %i(num_hours) => [:environment] do |_task, args|
    include CommitWrap
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    num_hours = args[:num_hours].to_i

    puts "Getting Products updated in the last #{num_hours} hours".yellow

    puts '=========================================='.magenta
    puts '|       Updating Product Cache             |'.magenta
    puts '=========================================='.magenta

    Spree::Supplier.installed.find_each do |supplier|
      next unless supplier.shopify_supplier?

      puts "Dealing with #{supplier.id}:#{supplier.domain}".yellow
      supplier.cache_shopify_products_async!(num_hours: num_hours)
    end
    puts 'Completed!'.green
  end

  # Update Event Cache - rake supplier:update_events_cache[60]
  desc 'Update Event Cache'
  task :update_event_cache, %i(num_hours) => [:environment] do |_task, args|
    include CommitWrap
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    num_hours = args[:num_hours].to_i

    puts "Getting Products updated in the last #{num_hours} hours".yellow

    puts '=========================================='.magenta
    puts '|       Updating Event Cache             |'.magenta
    puts '=========================================='.magenta

    Spree::Supplier.installed.find_each do |supplier|
      next unless supplier.shopify_supplier?

      puts "Dealing with #{supplier.id}:#{supplier.domain}".yellow
      supplier.cache_shopify_events_async!(num_hours: num_hours)
    end
    puts 'Completed!'.green
  end
end
