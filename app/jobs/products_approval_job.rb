class ProductsApprovalJob < ApplicationJob
  queue_as :shopify_import

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    product_ids = job.option_4.split(',')
    job.update(total_num_of_records: product_ids.count)

    Spree::Product.where(id: product_ids).find_in_batches do |products|
      products.each(&:skip_middle_steps_and_approve!)
    end

    job.complete_job! if job.may_complete_job?
  end
end
