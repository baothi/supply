class Csv::Export::OrdersFulfillmentMonitoringWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'csv_export',
                  backtrace: true

  attr_accessor :job

  HEADER = ['Line Item', 'Retailer Name', 'Shopify Order # (Retailer)', 'Supplier Name',
            'Shopify Order # (Supplier)', 'Fulfillment status from supplier cache',
            'Fulfillment status from system', 'Supplier Shopify Line Item ID'].freeze

  def perform(job_id)
    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    from = @job.hash_option_1[:from_date]
    to = @job.hash_option_1[:to_date]
    retailer_id = @job.retailer_id

    @orders = Spree::Order.where('created_at BETWEEN ? AND ?', from, to)
    @orders = @orders.where(retailer_id: retailer_id) if retailer_id.present?

    begin
      generate_report
    rescue => ex
      puts "#{ex}".red
      @job.log_error(ex) if @job.present?
      Rollbar.error(ex)
    end
  end

  private

  def generate_report
    @job.update(total_num_of_records: @orders.count)

    Axlsx::Package.new do |p|
      p.use_shared_strings = true

      p.workbook.add_worksheet(name: 'Orders Fulfillment Monitoring') do |sheet|
        add_header sheet
        export_content_to_rows sheet
      end

      send_report_via_email package: p
    end
    @job.mark_job_as_complete!
  end

  def send_report_via_email(package:)
    # Generate file & attach to job
    file = Tempfile.new(['temporary', '.xlsx'])
    file.binmode
    file.write(package.to_stream.read)
    file.rewind

    OperationsMailer.email_admin_with_attachment(
      subject: "#{DateTime.now.strftime('%m/%d')} Orders Fulfillment Monitoring Report",
      message: 'See attached for Orders Fulfillment Monitoring Report',
      file_path: file.path,
      file_name: "orders-fulfillment-report-#{Time.now.getutc.to_i}.xlsx"
    ).deliver_now
  end

  def export_content_to_rows(sheet)
    @orders.each do |order|
      supplier = order.supplier
      retailer = order.retailer

      shopify_order = ShopifyCache::Order.find_shopify_supplier_order(
        supplier_shopify_identifier: order.supplier_shopify_identifier,
        supplier: supplier
      )

      next if shopify_order.nil?

      order.line_items.each do |line_item|
        begin
          add_row(order, shopify_order, line_item, retailer, supplier, sheet)
        rescue => e
          puts "#{e}".red
          puts "#{e.backtrace}".red
        end
      end
      @job.update_status(true)
    end
  end

  def add_row(order, shopify_order, line_item, retailer, supplier, sheet)
    red = sheet.styles.add_style(bg_color: 'FF0000', fg_color: '000000')
    fulfillment_status_cache = shopify_order.fulfillment_status.downcase
    fulfillment_status_system = order.fulfillment_state_display.downcase
    style = fulfillment_status_system != fulfillment_status_cache ? red : nil

    sheet.add_row [
      line_item.name, retailer.name, order.retailer_shopify_order_number, supplier.name,
      order.supplier_shopify_order_number, fulfillment_status_cache.humanize,
      fulfillment_status_system.humanize, line_item.supplier_shopify_identifier
    ], style: style
  end

  def add_header(sheet)
    grey = sheet.styles.add_style(bg_color: 'A9A9A9', fg_color: '000000')
    sheet.add_row HEADER, style: grey
  end
end
