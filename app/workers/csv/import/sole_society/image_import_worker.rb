class Csv::Import::SoleSociety::ImageImportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob
  include ImportableJob

  sidekiq_options queue: 'csv_import',
                  backtrace: true

  attr_accessor :job

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    begin
      product_ids = []
      file = get_file_content(job)
      data = CSV.parse(file, headers: true, col_sep: "\t")
      variant_rows = data.map(&:to_hash)

      variant_rows.each do |row|
        variant = Spree::Variant.find_by(original_supplier_sku: row['id'])
        if variant.present? && variant.image_urls.blank? && row['image_link'].present?
          variant.update_columns(image_urls: [row['image_link']])
          product_ids << variant.product_id
        end
      end

      import_images(product_ids)
    rescue => ex
      # job.log_error(ex)
      puts "#{ex}".red
      puts "#{ex.backtrace}".red
    end
  end

  def import_images(product_ids)
    product_ids.each do |product_id|
      job = create_image_download_job(product_id)
      Shopify::ImportProductImageJob.perform_later(job.internal_identifier)
    end
  end

  def create_image_download_job(product_id)
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'images_import',
      initiated_by: 'user',
      option_1: product_id
    )
  end
end
