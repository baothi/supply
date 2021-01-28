module Reports
  class OrdersPerformanceReportJob < ApplicationJob
    queue_as :exports

    def perform(job_id)
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      @job.initialize_and_begin_job! unless @job.in_progress?
      @file = nil

      begin
        generate_csv
        generate_report
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end

    def generate_csv
      begin
        @job.update(total_num_of_records: 1)

        CSV.generate do |csv|
          # Now Collect Data
          fields = {
              num_amazon_orders: Spree::Order.num_amazon_orders,
              amazon_revenue: Spree::Order.amazon_revenue,
              num_ebay_orders: Spree::Order.num_ebay_orders,
              ebay_revenue: Spree::Order.ebay_revenue,
              total_revenue: Spree::Order.revenue_to_date,
              total_number_of_orders: Spree::Order.number_of_orders,
              total_unpaid_orders: 'TBD',
              total_paid_orders: 'TBD'
          }

          csv << fields.keys
          csv << fields.values

          @job.update_status(true)

          @raw_content = csv.string
          @file = StringIO.new(@raw_content)
        end
      rescue => ex
        @job.log_error(ex)
      end
    end

    def generate_report
      raise 'File is needed' if @file.nil?

      @job.output_csv_file = @file
      @job.output_csv_file.instance_write(:content_type, 'text/csv')
      @job.output_csv_file.instance_write(:file_name, "orders-#{Time.now.getutc.to_i}.csv")
      @job.complete_job! unless @job.completed?

      @job.save!

      OperationsMailer.email_admin(
        "Orders Performance Report - #{DateTime.now}",
        'See attached for Orders Performance Report', @raw_content
      ).deliver_now
    end
  end
end
