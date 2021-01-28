class Shopify::ProductUpdateWorker
  include Sidekiq::Worker
  include CancellableJob

  sidekiq_options queue: 'shopify_product_import',
                  backtrace: true,
                  retry: 2

  def process_for_webhook(job)
    shopify_product = JSON.parse(job.option_2, object_class: OpenStruct)
    updater_service = Shopify::Product::Updater.new(
      supplier_id: job.supplier_id,
      shopify_product: shopify_product
    )
    job.update(total_num_of_records: 1)
    status = updater_service.perform
    job.update_status(status)
    updater_service
  end

  def process_for_ids(job)
    updater_service = Shopify::Product::Updater.new(
      supplier_id: job.supplier_id
    )

    product_ids = job.option_4.split(',')
    job.update(total_num_of_records: product_ids.count)

    product_ids.each do |shopify_identifier|
      return if cancelled?

      status = updater_service.perform(shopify_identifier)
      job.update_status(status)
    end
    updater_service
  end

  def log_results_and_complete_job(updater_service, job)
    job.log_error(updater_service.errors)
    job.update_log(updater_service.logs)
    job.complete_job! if job.may_complete_job?
  end

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    supplier = Spree::Supplier.find_by(id: job.supplier_id)
    begin
      raise 'No Supplier found' unless supplier.present?

      if job.option_1 == 'webhook'
        updater_service = process_for_webhook(job)
      else
        raise 'Could not connect to Shopify' unless supplier.initialize_shopify_session!

        updater_service = process_for_ids(job)
      end

      log_results_and_complete_job(updater_service, job)
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end
  end
end
