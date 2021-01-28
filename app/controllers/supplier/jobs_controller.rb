class Supplier::JobsController < Supplier::BaseController
  def index
    @jobs = Spree::LongRunningJob.initiated_by(current_supplier).order('created_at desc')
  end

  def details
    @job = Spree::LongRunningJob.find_by!(internal_identifier: params[:id])
  end

  def download_csv
    job = Spree::LongRunningJob.find_by(internal_identifier: params[:id])
    data = open(job.output_csv_file.url)
    send_data data.read,
              filename: "#{job.output_csv_file_file_name}",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def history; end

  def recurring; end

  def errors; end
end
