class Shopify::Variant::OptionsUploadWorker
  include Sidekiq::Worker

  include ImportableJob
  include CancellableJob

  sidekiq_options queue: 'product_import',
                  backtrace: true,
                  retry: 3

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?
    @supplier = Spree::Supplier.find_by(id: job.supplier_id)

    begin
      uploaded_variants_hash = extract_data_from_job_file(job)
    rescue => e
      job.log_error(e.to_s)
      JobsMailer.shopify_csv_upload_error(job.id).deliver_now
      return
    end

    job.update(total_num_of_records: uploaded_variants_hash&.length)

    uploaded_variants_hash.each do |hsh|
      break if cancelled?

      begin
        status = update_variant_options(hsh)
        job.update_status(status)
      rescue => e
        job.log_error(e.to_s)
        job.update_status(false)
      end
    end
    job.complete_job! if job.may_complete_job?
    JobsMailer.shopify_csv_upload_success(job.id).deliver_now
  end

  def update_variant_options(hsh)
    variants = @supplier.variants.where('original_supplier_sku iLIKE ?', hsh['Variant SKU'])
    return false unless variants.present?

    variants.each do |variant|
      update_option_values(variant, hsh)
    end
    true
  end

  def update_option_values(variant, hsh)
    return if variant.supplier_color_value.present? && variant.supplier_size_value.present?

    color_name = hsh['Color']&.upcase
    size_name = hsh['Size']&.upcase

    if color_name.present? && variant.supplier_color_value.blank?
      variant.set_option_value('Color', color_name)

      ActiveRecord::Base.transaction do
        supplier_color_option = variant.create_supplier_color_option(color_name)

        variant.update_columns(
          supplier_color_value: color_name,
          supplier_color_option_id: supplier_color_option.id
        )
      end
    end

    return unless size_name.present? && variant.supplier_size_value.blank?

    variant.set_option_value('Size', size_name)

    ActiveRecord::Base.transaction do
      supplier_size_option = variant.create_supplier_size_option(size_name)

      variant.update_columns(
        supplier_size_value: size_name,
        supplier_size_option_id: supplier_size_option.id
      )
    end
  end
end
