module Dsco
  module Order
    class BatchExporterJob < ApplicationJob
      include DscoOrderExportCsvGenerator

      queue_as :order_export

      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        @supplier = Spree::Supplier.find_by(id: @job.supplier_id)
        orders = @supplier.orders.paid.unfulfilled
        @job.update(total_num_of_records: orders.count)
        @raw_content = generate_dsco_export_file(orders.pluck(:id))
        raise 'Could not generate dsco export file' unless @raw_content.present?

        @file = StringIO.new(@raw_content)

        if @file.present?
          send_file_to_ftp
          orders.map(&:complete_remittance!)
        end

        @job.complete_job! unless @job.completed?
      end

      def send_file_to_ftp
        begin
          filename = "#{@supplier.slug}_dsco_orders_export_#{Time.now.getutc.to_i}.csv"
          @job.output_csv_file = @file
          @job.output_csv_file.instance_write(:content_type, 'text/csv')
          @job.output_csv_file.instance_write(:file_name, filename)
          @job.complete_job! unless @job.completed?
          @job.save!

          dsco_file_name = "Purchase_Order_bulk_#{Time.now.getutc.to_i}.csv"
          url = if Rails.env.development?
                  "#{Rails.root}/public#{@job.output_csv_file.url(:original, timestamp: false)}"
                else
                  @job.output_csv_file.url
                end
          contents = open(url).read

          file = Supply::TemporaryFileHelper.temp_file(contents, 'csv')
          Dsco::Ftp.new.upload(file, dsco_file_name)
        rescue => e
          @job.log_error(e.to_s)
        end
      end
    end
  end
end
