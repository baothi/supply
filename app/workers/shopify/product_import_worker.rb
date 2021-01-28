class Shopify::ProductImportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'shopify_import',
                  backtrace: true,
                  retry: 3

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    begin
      importer = Shopify::Product::Importer.new(
        supplier_id: job.supplier_id
      )
      shopify_product = JSON.parse(job.option_2, object_class: OpenStruct)
      importer.perform(shopify_product)
      job.log_error(importer.errors)
      job.update_log(importer.logs)
      job.complete_job! if job.may_complete_job?
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      store exceptions: e.to_s
      return
    end
  end
end
