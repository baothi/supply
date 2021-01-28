module Karmaloop
  class OrderImportJob < ApplicationJob
    queue_as :shopify_export

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        retailer = Spree::Retailer.find(job.retailer_id)

        job_file = if Rails.env.development?
                     open("#{Rails.root}/public#{job.input_csv_file.url(
                       :original, timestamp: false
                     )}", 'r')
                   else
                     open(job.input_csv_file.url, 'r')
                   end

        contents = SmarterCSV.process(job_file)
        job.update(total_num_of_records: contents.count)

        valid = Karmaloop::Order::Validator.new(lines: contents).perform
        raise 'Invalid Line Items Found' unless valid

        Karmaloop::Order::Recreator.new(retailer: retailer, lines: contents).perform
      rescue => ex
        job.log_error(ex)
      end
    end
  end
end
