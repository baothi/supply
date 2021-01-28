require 'spree'

namespace :products do
  desc 'Generates product searchable attributes'
  task :bulk_generate_searchable_attributes, %i(start end) => :environment do |_t, args|
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_1: args[:start].to_i,
      option_2: args[:end].to_i
    )
    Products::ProductSearchAttributesRefreshJob.perform_later(job.internal_identifier)
  end

  desc 'Approves products in bulk'
  task :bulk_approve_products, %i(start end) => :environment do |_t, args|
    product_ids = (args[:start]..args[:end]).to_a
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_4: product_ids.join(',')
    )

    ProductsApprovalJob.perform_later(job.internal_identifier)
  end

  desc 'Update Counter Cache'
  task update_image_counter: :environment do
    puts 'Begin scheduling product counter cache update'.green
    min_id = Spree::Product.minimum(:id)
    max_id = Spree::Product.maximum(:id)
    Spree::Product.update_all_image_counters!(min_id, max_id, 500)
    puts 'Done scheduling product counter cache update'.green
  end

  desc 'Update Compliance Cache'
  task update_compliance_cache: :environment do
    puts 'Begin scheduling product compliance cache update'.green
    min_id = Spree::Product.minimum(:id)
    max_id = Spree::Product.maximum(:id)
    Spree::Product.update_all_cached_compliance_status_info!(min_id, max_id, 500)
    puts 'Done scheduling product compliance cache update'.green
  end

  desc 'Update DSCO Inventories'
  task update_dsco_inventories: :environment do
    sftp = Net::SFTP.start(
      ENV['DSCO_FTP_HOST'],
      ENV['DSCO_FTP_USER'],
      password: ENV['DSCO_FTP_PASSWORD']
    )

    inventory_files = sftp.dir.glob('/out', 'Inventory_*.csv')

    inventory_files.each do |inventory_file|
      contents = sftp.file.open("out/#{inventory_file.name}").read

      tmpfile = Tempfile.new([inventory_file.name.split('.')[0], '.csv'])
      tmpfile.binmode
      tmpfile.write(contents)
      tmpfile.rewind

      job = Spree::LongRunningJob.new(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        input_csv_file: tmpfile
      )
      if job.save
        Dsco::Product::InventoryUpdateWorker.perform_later(job.internal_identifier)
        sftp.rename!("out/#{inventory_file.name}", "out/archive/#{inventory_file.name}")
      end
    end
  end
end
