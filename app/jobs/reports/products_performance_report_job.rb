module Reports
  class ProductsPerformanceReportJob < ApplicationJob
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

        products = Spree::Product.all
        total_num_of_records = products.count

        @job.update(total_num_of_records: total_num_of_records)

        CSV.generate do |csv|
          fields = %i(id
                      name
                      shopify_vendor
                      license_name
                      discontinue_on
                      valid_count_on_hand
                      revenue_from_product
                      number_of_orders_with_product
                      revenue_generated_for_retailers
                      shopify_product_type)

          header = fields.map(&:to_s)

          csv << header

          products.find_in_batches do |group|
            group.each do |order|
              row = fields.map { |field| order.public_send(field.to_s) }

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

    def generate_report
      raise 'File is needed' if @file.nil?

      @job.output_csv_file = @file
      @job.output_csv_file.instance_write(:content_type, 'text/csv')
      @job.output_csv_file.instance_write(:file_name, "retailer-#{Time.now.getutc.to_i}.csv")
      @job.complete_job! unless @job.completed?

      @job.save!

      OperationsMailer.email_admin(
        "Product Performance Report - #{DateTime.now}",
        'See attached for Product Performance Report', @raw_content
      ).deliver_now
    end
  end
end
