class Size::UpdateSupplierProductsSizesJob < ApplicationJob
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
      # This creates & assigns all the supplier color options found
      supplier.create_sizes_from_option_types!

      subject = "[Size Options] Processed ~ #{supplier.products.count} products"
      body = "The platform has completed creating new options for #{supplier.name}.<br><br>"\
        ' The complete list of options for this supplier is as follows: <br><br>'\
        "#{supplier.supplier_size_options.map(&:name).join(',')}<br><br>"\
        'You will want to ensure all of these values are mapped to our platform colors'

      email_results_to_operations!(subject, body)

      puts 'Finished finding all the sizes!'.green
    rescue => ex
      puts "#{ex}".red
      Rollbar.error(ex,
                    supplier_name: supplier.name,
                    supplier_id: supplier.id)
    end

    job.complete_job! if job.may_complete_job?
  end
end