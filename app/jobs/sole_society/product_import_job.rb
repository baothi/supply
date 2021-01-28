module SoleSociety
  class ProductImportJob < ApplicationJob
    queue_as :shopify_import

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        supplier = Spree::Supplier.find(job.supplier_id)

        job_file = if Rails.env.development?
                     open("#{Rails.root}/public#{job.input_csv_file.url(
                       :original, timestamp: false
                     )}", 'r')
                   else
                     open(job.input_csv_file.url, 'r')
                   end

        SoleSociety::Variant::Importer.new(job_file, supplier).perform
      rescue => ex
        # job.log_error(ex)
        puts "#{ex}".red
        puts "#{ex.backtrace}".red
      end
    end
  end
end
