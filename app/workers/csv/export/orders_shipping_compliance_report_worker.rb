class Csv::Export::OrdersShippingComplianceReportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'csv_export',
                  backtrace: true

  attr_accessor :job, :csv

  HEADER = ['Retailer', 'Retailer Email', 'Supplier', 'Supplier Email', 'Retailer Order #',
            'Supplier Order #', 'Order Date', 'Paid Date', 'Ship Name', 'Ship Address Line 1',
            'Ship Address Line 2', 'City', 'State', 'Zip Code', 'Country', 'Sku', 'Product Title',
            'Supplier Color Value', 'Supplier Size Value', 'Master MSRP (at time of order)',
            'Master Cost (at time of order)', 'Quantity', 'Subtotal (Master Cost x Qty)',
            'Shipping', 'Total (Subtotal + Shipping)'].freeze

  def perform(job_id)
    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?
    @file = nil
    from = @job.hash_option_1[:from_date]
    to = @job.hash_option_1[:to_date]
    supplier_id = @job.supplier_id

    @orders = Spree::Order.paid.unfulfilled.where('shopify_sent_at BETWEEN ? AND ?', from, to)
    @orders = @orders.where(supplier_id: supplier_id) if supplier_id.present?

    begin
      generate_csv
      generate_report
    rescue => ex
      puts "#{ex}".red
      @job.log_error(ex) if @job.present?
    end
  end

  private

  def generate_csv
    begin
      @job.update(total_num_of_records: @orders.count)

      CSV.generate do |csv|
        # Now Collect Data
        csv << HEADER
        @orders.each do |order|
          order.line_items.each do |line_item|
            begin
              csv << get_row(order, line_item)
            rescue => e
              Rollbar.error(e)
            end
          end
          @job.update_status(true)
        end

        @raw_content = csv.string
        @file = StringIO.new(@raw_content)
      end
    rescue => ex
      @job.log_error(ex)
    end
  end

  def generate_report
    raise 'File is needed' if @file.nil?

    filename =  "unfulfilled-orders-#{Time.now.getutc.to_i}.csv"
    @job.output_csv_file = @file
    @job.output_csv_file.instance_write(:content_type, 'text/csv')
    @job.output_csv_file.instance_write(:file_name, filename)
    @job.complete_job! unless @job.completed?

    @job.save!

    OperationsMailer.email_admin(
      "Orders Compliance Shipping Report - #{DateTime.now}",
      'See attached for Orders Compliance Reports for Shipping', @raw_content
    ).deliver_now
  end

  def get_row(order, line_item)
    shipping_address = order.shipping_address
    [
      order.retailer.name, order.retailer.email, order.supplier.name, order.supplier.email,
      "'#{order.retailer_shopify_name}", "'#{order.supplier_shopify_order_name}",
      order.created_at.strftime('%m/%d/%Y'), order.shopify_sent_at.strftime('%m/%d/%Y'),
      "#{shipping_address&.firstname} #{shipping_address&.lastname}", shipping_address&.address1,
      shipping_address&.address2, shipping_address&.city, shipping_address&.name_of_state,
      "'#{shipping_address&.zipcode}", shipping_address&.country,
      "'#{line_item.original_supplier_sku}", line_item.name, line_item.variant.supplier_color_value,
      line_item.variant.supplier_size_value, line_item.variant.master_msrp.to_f,
      line_item.variant.master_cost.to_f, line_item.quantity, line_item.subtotal,
      line_item.line_item_shipping_cost.to_f, line_item.line_item_cost_with_shipping
    ]
  end
end
