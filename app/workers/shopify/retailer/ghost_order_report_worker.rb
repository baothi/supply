class Shopify::Retailer::GhostOrderReportWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob

  sidekiq_options queue: 'order_export',
                  backtrace: true

  attr_accessor :job,
                :csv,
                :definitive_orders,
                :potential_orders,
                :definitive_csv,
                :potential_csv

  def perform(job_id)
    return if cancelled?

    @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?
    @retailer = Spree::Retailer.find(@job.retailer_id)

    auditor = Shopify::Audit::GhostOrderAuditor.new(
      retailer: @retailer,
      from: @job.option_1,
      to: @job.option_2
    )

    begin
      auditor.perform
      @definitive_orders = auditor.all_hingeto_orders
      @potential_orders = auditor.potential_orders_based_on_sku
      num_records = @definitive_orders.count + @potential_orders.count
      job.update(total_num_of_records: num_records)
    rescue => ex
      Rollbar.error(ex)
      puts "Error: #{ex}".red
    end

    @definitive_orders = auditor.all_hingeto_orders
    @potential_orders = auditor.potential_orders_based_on_sku

    @definitive_csv = generate_csv(@definitive_orders)
    @potential_csv = generate_csv(@potential_orders)
    # save_csv_file_to_job
    notify_job_completion
  end

  private

  def generate_csv(orders)
    CSV.generate(force_quotes: true, headers: true) do |csv_stream|
      csv_stream << headers
      orders.each do |order|
        begin
          csv_stream << body.map { |field| order.send(field) }
          job.update_status(true)
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
      'Retailer Order ID' => :id,
      'Retailer Order Name' => :name,
      'Financial Status' => :financial_status
    }
  end

  # def save_csv_file_to_job
  #   job.output_csv_file = StringIO.new(csv.string)
  #   job.output_csv_file.instance_write(:content_type, 'text/csv')
  #   job.output_csv_file.instance_write(:file_name, filename)
  #   job.complete_job! unless job.completed?
  #   job.save!
  # end

  def notify_job_completion
    time = Time.zone.now.to_s.parameterize.underscore
    files = {
        "potential_orders_#{time}.csv": potential_csv.string,
        "definitive_orders_#{time}.csv": definitive_csv.string
    }
    JobsMailer.notify_job_completion(
      job,
      files,
      "Ghost Order Import for #{@retailer.name}"
    ).deliver_now
  end
end
