module Reports
  class RetailersPerformanceReportJob < ApplicationJob
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
        index = 0

        retailers = Spree::Retailer.all
        total_num_of_records = retailers.count

        @job.update(total_num_of_records: total_num_of_records)

        CSV.generate do |csv|
          fields = %i(id
                      slug
                      shopify_url
                      number_of_orders
                      date_of_install
                      avg_num_of_days_to_first_order
                      avg_num_of_days_to_first_order_at_shopify
                      has_product?
                      num_live_products
                      num_amazon_orders amazon_revenue
                      num_ebay_orders ebay_revenue
                      revenue_to_date)

          header = fields.map(&:to_s)
          csv << header

          retailers.find_in_batches do |group|
            group.each do |order|
              row = fields.map { |field| order.public_send(field.to_s) }

              csv << row

              index += 1

              if  (index % 10).zero?
                @job.progress = (index.to_f / total_num_of_records) * 100
                # puts "Should be updating progress to #{@job.progress}"
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

    def generate_report
      raise 'File is needed' if @file.nil?

      @job.output_csv_file = @file
      @job.output_csv_file.instance_write(:content_type, 'text/csv')
      @job.output_csv_file.instance_write(:file_name, "retailer-#{Time.now.getutc.to_i}.csv")
      @job.complete_job! unless @job.completed?

      @job.save!

      OperationsMailer.email_admin(
        "Retailer Performance Report - #{DateTime.now}",
        'See attached for the generated Retailer Performance Reports', @raw_content
      ).deliver_now
    end
  end
end
