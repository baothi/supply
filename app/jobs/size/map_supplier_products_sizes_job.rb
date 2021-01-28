class Size::MapSupplierProductsSizesJob < ApplicationJob
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
      # This creates & assigns all the shipping / supplier category options & more.
      product_count = supplier.assign_supplier_products_to_platform_size_options!

      subject = "[Size Mapping] Processed #{product_count} products"
      body = "The platform has completed size mapping for #{supplier.name}.<br><br>"\
      'Please login to ensure that all looks good.'
      email_results_to_operations!(subject, body)

      puts 'Finished mapping all the sizes!'.green
    rescue => ex
      puts "#{ex}".red
      Rollbar.error(ex,
                    supplier_name: supplier.name,
                    supplier_id: supplier.id)
    end

    job.complete_job! if job.may_complete_job?
  end
end
