class Dsco::Product::BatchMsrpPriceAppendWorker
  include Sidekiq::Worker
  include ImportableJob
  include CancellableJob

  sidekiq_options queue: 'product_import',
                  backtrace: true,
                  retry: 3

  attr_accessor :job

  def perform(job_id)
    return if cancelled?

    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    begin
      batch_append_msrp
    rescue => e
      @job.log_error(e.to_s)
    end

    # @job.complete_job! if @job.may_complete_job?
  end

  def batch_append_msrp
    sheet_rows = extract_data_from_job_file(@job)
    total_records = sheet_rows.count
    @job.update(total_num_of_records: total_records)
    msrp_guesser = Dsco::Product::MsrpGuesser.new

    # For output file
    header = ['Variant SKU',
              'MAP Price',
              'MSRP Price',
              'Wholesale Cost']

    CSV.generate do |csv|
      csv << header
      sheet_rows.each_with_index do |row, index|
        begin
          row_hash = row.with_indifferent_access
          msrp_guesser.perform(row_hash)
          @job.update_status(msrp_guesser.status)

          csv << [
              row_hash['sku']&.upcase,
              msrp_guesser.msrp,
              msrp_guesser.msrp,
              row_hash['cost']&.upcase
          ]
          # For development environment
          break if Rails.env.development? && (index >= 200)
        rescue => e
          @job.log_error(e.to_s)
        end
      end

      save_csv_file_to_job(csv)
    end
  end

  def save_csv_file_to_job(csv)
    filename = "product_msrp_download_#{Time.now.getutc.to_i}.csv"
    @job.output_csv_file = StringIO.new(csv.string)
    @job.output_csv_file.instance_write(:content_type, 'text/csv')
    @job.output_csv_file.instance_write(:file_name, filename)
    @job.complete_job! unless @job.completed?
    @job.save!
    ProductsMailer.products_csv_download(@job, csv.string).deliver_now
  end
end
