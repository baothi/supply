class Shopify::RetailerBulkInventoryUpdateWorker
  include Sidekiq::Worker
  include CancellableJob

  sidekiq_options queue: 'shopify_export',
                  backtrace: true,
                  retry: false

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    begin
      updater = Shopify::Product::BulkInventoryUpdater.new(retailer_id: job.retailer_id)
      ro = updater.perform
      raise ro.message unless ro.success?
    rescue => e
      Rollbar.error(e, retailer_id: job&.retailer_id)
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end
  end
end
