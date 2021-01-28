module Csv
  module Export
    class OrdersByLineItemJob < ApplicationJob
      attr_reader :job, :params, :orders

      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job!
        set_orders(job.option_2)
        generate_csv if orders.any?
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex.to_s)
        job.raise_issue!
      end

      private

      def generate_csv
        counter = 0
        job.update(total_num_of_records: orders.size)
        CSV.generate(force_quotes: true) do |csv|
          headers = csv_fields.values
          body = csv_fields.keys
          csv << headers

          orders.find_each do |order|
            order.line_items.each do |li|
              csv << body.map { |field| li.send(field) }
            end
            if (counter % 10).zero?
              job.update(progress: percentage_progress(counter, orders.size))
            end
          end

          save_csv_file_to_job(csv)
        end
      end

      def set_orders(option)
        @params = JSON.parse(option)
        @orders = if params['scope']
                    Spree::Order.send(params['scope']).ransack(params).result
                  else
                    Spree::Order.ransack(params).result
                  end
      end

      def csv_fields
        {
          created_at: 'Date Created',
          order_completed_at: 'Date Completed',
          order_name: 'Order Name',
          supplier_name: 'Supplier',
          retailer_name: 'Retailer',
          order_risk_recommendation: 'Risk Level',
          shipment_state: 'Shipment Status',
          order_payment_state_display: 'Payment Status',
          line_item_shipping_cost: 'Shipping Cost',
          line_item_cost_without_shipping: 'Cost Without Shipping',
          line_item_cost_with_shipping: 'Cost With Shipping'
        }
      end

      def save_csv_file_to_job(csv)
        job.output_csv_file = StringIO.new(csv.string)
        job.output_csv_file.instance_write(:content_type, 'text/csv')
        job.output_csv_file.instance_write(:file_name, filename)
        @job.complete_job! unless @job.completed?
        job.save!

        JobsMailer.notify_job_completion(job, csv.string, job.option_1).deliver_now
      end

      def filename
        "orders_#{params['scope'] || :all}_#{Time.now.getutc.to_i}.csv"
      end

      def percentage_progress(counter, size)
        (counter.to_f / size) * 100
      end
    end
  end
end
