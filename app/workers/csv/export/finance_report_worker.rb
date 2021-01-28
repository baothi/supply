# For syncing all supplier products
class Csv::Export::FinanceReportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'csv_export',
                  backtrace: true

  attr_accessor :job, :csv

  def perform(job_id)
    return if cancelled?

    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?
    @csv = generate_csv(JSON.parse(job.option_1))
    return if csv.nil?

    save_csv_file_to_job
    notify_job_completion
  end

  private

  def generate_csv(params)
    CSV.generate(force_quotes: true, headers: true) do |csv_stream|
      csv_stream << headers
      Spree::LineItem.ransack(params).result.
        find_in_batches(batch_size: 250).with_index do |line_items, batch|
        begin
          puts "PROCESSING BATCH: ##{batch}".green
          job.update(total_num_of_records: line_items.length)
          line_items.each do |li|
            csv_stream << body.map { |field| li.send(field) }
            job.update_status(true)
          end
        rescue => e
          job.update_status(false)
          puts 'Error processing line items'.red
          puts e.backtrace
        end
      end
      @csv = csv_stream
    end
    csv
  end

  def headers
    csv_fields.keys
  end

  def body
    csv_fields.values
  end

  def csv_fields
    {
      'Retailer Order Name' => :order_retailer_shopify_name,
      'Supplier Order Name' => :order_supplier_shopify_order_name,
      'Hingeto Order Number' => :order_number,
      'Date Created On Shopify' => :order_completed_at,
      'Date Created On Hingeto' => :created_at,
      'Product Title' => :product_title,
      'Original Supplier SKU' => :variant_original_supplier_sku,
      'Platform Supplier SKU' => :variant_platform_supplier_sku,
      'Supplier' => :supplier_name,
      'Retailer' => :retailer_name,
      'Payment Sources' => :order_payment_sources,
      'Shipment State' => :shipment_state,
      'Ship Date' => :ship_date,
      '(Broken) Ship Date' => :broken_ship_date,
      'Tracking Number' => :tracking_numbers,
      'Payment State' => :order_payment_state_display,
      'Terms' => :terms,
      'Ordered Quantity' => :quantity,
      'Wholesale Cost' => :wholesale_cost,
      'MSRP Price' => :variant_msrp_price,
      'Sold At Price' => :sold_at_price,
      'Total Sales' => :total_sales,
      'Hingeto Commission' => :hingeto_commission,
      'Shipping' => :line_item_shipping_cost,
      'Shipping Country' => :shipping_country,
      'Supplier Payment Amount' => :supplier_payment_amount
    }
  end

  def save_csv_file_to_job
    job.output_csv_file = StringIO.new(csv.string)
    job.output_csv_file.instance_write(:content_type, 'text/csv')
    job.output_csv_file.instance_write(:file_name, filename)
    job.complete_job! unless job.completed?
    job.save!
  end

  def notify_job_completion
    JobsMailer.notify_job_completion(job, csv.string, 'Finance Report').deliver_now
  end

  def filename
    time = Time.zone.now.to_s.parameterize.underscore
    "finance_report_#{time}.csv"
  end
end
