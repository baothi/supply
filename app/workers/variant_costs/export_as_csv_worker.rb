module VariantCosts
  class ExportAsCsvWorker
    include Sidekiq::Worker

    include Spree::Calculator::PriceCalculator
    include CancellableJob

    sidekiq_options queue: 'product_import',
                    backtrace: true,
                    retry: 1

    attr_reader :long_job

    def perform(internal_identifier)
      @long_job = Spree::LongRunningJob.find_by(internal_identifier: internal_identifier)
      long_job.initialize_and_begin_job!
      query = JSON.parse(long_job.option_1)
      records = Spree::VariantCostCsv.custom_ransack(query).result
      # records = Spree::VariantCostCsv.all
      puts "#{records.inspect}".yellow
      generate_csv_for(records) if records
    rescue => ex
      puts "#{ex}".red
      Rollbar.error(ex)
      long_job.log_error(ex.to_s)
      long_job.raise_issue!
    end

    def generate_csv_for(records)
      begin
        counter = 0
        record_size = records.size
        long_job.update(total_num_of_records: record_size)
        CSV.generate do |csv|
          csv << Spree::VariantCostCsv.headers
          records.each do |record|
            csv << Spree::VariantCostCsv.body.map { |field| record.send(field) }
            if (counter % 10).zero?
              long_job.update(progress: percentage_progress(counter, record_size))
            end
          end
          save_csv_file_to_job(csv)
        end
      rescue => ex
        long_job.log_error(ex)
      end
    end

    def percentage_progress(counter, size)
      (counter.to_f / size) * 100
    end

    def save_csv_file_to_job(csv)
      filename = "product_csv_download_#{Time.now.getutc.to_i}.csv"
      long_job.output_csv_file = StringIO.new(csv.string)
      long_job.output_csv_file.instance_write(:content_type, 'text/csv')
      long_job.output_csv_file.instance_write(:file_name, filename)
      long_job.complete_job! unless long_job.completed?
      long_job.save!
      ProductsMailer.products_csv_download(long_job, csv.string).deliver_now
    end
  end
end
