class BulkExportJob < ApplicationJob
  queue_as :exports

  def perform(job_id)
    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    @klass = @job.option_1.constantize
    @fields = JSON.parse(@job.option_2)
    @filename = @job.option_3

    @file = nil

    begin
      generate_csv
      email_csv_to_admin
    rescue => ex
      puts "#{ex}".red
      @job.log_error(ex) if @job.present?
    end
  end

  def generate_csv
    begin
      index = 0

      records = @klass.all
      total_num_of_records = records.count

      @job.update(total_num_of_records: total_num_of_records)

      CSV.generate do |csv|
        header = @fields.map(&:to_s)

        csv << header

        records.find_in_batches do |group|
          group.each do |order|
            row = @fields.map { |field| order.public_send(field.to_s) }

            csv << row

            index += 1

            if  (index % 10).zero?
              @job.progress = (index.to_f / total_num_of_records) * 100
              @job.save!
            end

            @job.update_status(true)
          end
        end

        # puts "About to save the file.."

        @raw_content = csv.string
        @file = StringIO.new(@raw_content)
      end

      # @job.complete_job! unless @job.complete?
    rescue => ex
      @job.log_error(ex)
    end
  end

  def email_csv_to_admin
    raise 'File is needed' if @file.nil?

    filename = "#{@filename}_#{Time.now.getutc.to_i}.csv"
    @job.output_csv_file = @file
    @job.output_csv_file.instance_write(:content_type, 'text/csv')
    @job.output_csv_file.instance_write(:file_name, filename)
    @job.complete_job! unless @job.completed?

    @job.save!

    BulkExportMailer.email_admin(
      subject: "Bulk Export for #{@klass.name.demodulize} at  #{DateTime.now}",
      message: 'Please see attached for your requested export.',
      filename: filename,
      file: @raw_content
    ).deliver_now
  end
end
