module Shipping
  class ShippingMethodsExporterJob < ApplicationJob
    queue_as :exports

    def perform(job_id)
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      @job.initialize_and_begin_job! unless @job.in_progress?

      @supplier = Spree::Supplier.find_by(id: @job.supplier_id)

      shipping_methods = @supplier.shipping_methods
      @job.update(total_num_of_records: shipping_methods.count)
      @file = nil

      mapping = Spree::ShippingMethod::CSV_MAPPING
      header_row = mapping.values
      attributes = mapping.keys

      begin
        CSV.generate do |csv|
          csv << header_row
          shipping_methods.find_each do |shipping_method|
            csv << attributes.map { |attribute| shipping_method.public_send(attribute) }
            @job.update_status(true)
          end

          @raw_content = csv.string
          @file = StringIO.new(@raw_content)
        end
        email_csv_to_admin
      rescue => e
        @job.log_error(e)
      end
    end

    def email_csv_to_admin
      raise 'File is needed' if @file.nil?

      filename = "#{@supplier.slug}_shipping_methods_#{Time.now.getutc.to_i}.csv"
      @job.output_csv_file = @file
      @job.output_csv_file.instance_write(:content_type, 'text/csv')
      @job.output_csv_file.instance_write(:file_name, filename)
      @job.complete_job! unless @job.completed?

      @job.save!

      BulkExportMailer.email_admin(
        subject: "Shipping Methods for #{@supplier.name} at  #{DateTime.now}",
        message: 'Please see attached for your shipping methods export.',
        filename: filename,
        file: @raw_content
      ).deliver_now
    end
  end
end
