class Pricing::SetMarkupPriceJob < ApplicationJob
  queue_as :default

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    supplier = Spree::Supplier.find_by(id: job.supplier_id)
    job.update(total_num_of_records: supplier.variants.count)

    supplier.variants.find_each do |variant|
      platform_marked_up_price = variant.send(:calc_price,
                                              variant.price,
                                              supplier.instance_type,
                                              supplier.default_markup_percentage)

      status = variant.update(price: platform_marked_up_price)
      job.update_status(status)
    end

    job.complete_job! if job.may_complete_job?
  end
end
