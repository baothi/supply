class Category::MapSupplierProductsJob < ApplicationJob
  include Emailable

  queue_as :default

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    supplier = Spree::Supplier.find_by(id: job.supplier_id)
    # Number of suppliers, since we have no plans to iterate through
    # all the products directly.. just the unique number of categories

    job.update(total_num_of_records: 1)

    begin
      # This will clear out any Taxons on the Product and add the latest matched version
      supplier.assign_supplier_products_to_platform_category_options!

      subject = "[Category Mapping] Mapping completed for #{supplier.name}"
      body = "The platform has completed color mapping for #{supplier.name}.<br><br>"\
      'Please login to ensure that all looks good.'
      email_results_to_operations!(subject, body)
    rescue => ex
      puts "#{ex}".red
      Rollbar.error(ex,
                    supplier_name: supplier.name,
                    supplier_id: supplier.id)
    end

    job.complete_job! if job.may_complete_job?
  end
end
