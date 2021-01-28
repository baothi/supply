class Shopify::SyndicateInventoryWorker
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
      variant_id = job.option_1

      variant = Spree::Variant.find(variant_id)
      variant_listings = variant.variant_listings
      job.update(total_num_of_records: variant_listings.count)

      variant_listings.each do |variant_listing|
        break if cancelled?

        begin
          updater = Shopify::Product::LiveInventoryUpdater.new(
            retailer_id: job.retailer_id,
            variant_listing: variant_listing,
            variant: variant
          )
          updater.perform
          job.update_status(true)
        rescue => ex
          puts "Issue Updating for #{variant_listing.internal_identifier} "\
              "for #{variant_listing.retailer.name}"
          puts "#{ex}".red
          job.update_status(false)
          job.log_error(ex.to_s)
        end
      end
    rescue => e
      job.log_error(e.to_s)
      job.raise_issue!
      return
    end
  end
end
