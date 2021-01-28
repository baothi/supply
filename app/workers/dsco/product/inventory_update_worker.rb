class Dsco::Product::InventoryUpdateWorker
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

    contents = extract_data_from_job_file(job)
    inventories = contents.map(&:to_hash)
    job.update(total_num_of_records: inventories.length)

    inventories.each do |hsh|
      begin
        variant = Spree::Variant.find_by(dsco_identifier: hsh['dsco_item_id'])
        status = variant.present? ? update_stock(variant, hsh['quantity_available']) : true
        job.update_status(status)
      rescue => e
        job.log_error(e.to_s)
        job.update_status(false)
      end
    end
    job.complete_job! if job.may_complete_job?
  end

  def update_stock(variant, quantity_available)
    variant.stock_items.update_all(count_on_hand: quantity_available)
  end
end
