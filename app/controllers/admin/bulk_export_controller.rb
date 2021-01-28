class Admin::BulkExportController < BaseController
  protect_from_forgery with: :exception

  before_action :set_klass, only: :csv

  def csv
    if @klass.all.empty?
      redirect_to :back, alert: 'There are no records to export'
    else
      job = Spree::LongRunningJob.new(
        action_type: 'export',
        job_type: job_type,
        initiated_by: 'user',
        user_id: current_spree_user.id,
        option_1: params[:klass_name],
        option_2: params[:columns],
        option_3: "#{job_type}"
      )

      if job.save
        BulkExportJob.perform_later(job.internal_identifier)
        notice = "You will be emailed at #{ENV['SUPPLIER_EMAIL']} once the export in completed."
        redirect_to admin_data_import_export_status_path(job.id), notice: notice.html_safe
      else
        puts job.errors.inspect
        redirect_to :back, alert: 'Unable to create job'
      end
    end
  end

  def dsco_orders
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = Spree::LongRunningJob.new(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      supplier_id: supplier.id
    )

    if job.save
      Dsco::Order::BatchExporterJob.perform_later(job.internal_identifier)
      notice = "You will be emailed at #{ENV['SUPPLIER_EMAIL']} once the export in completed."
      redirect_to admin_data_import_export_status_path(job.id), notice: notice.html_safe
    else
      redirect_to :back, alert: 'Unable to create job'
    end
  end

  private

  def job_type
    "#{params[:klass_name].demodulize.underscore.pluralize}_export"
  end

  def set_klass
    @klass = params[:klass_name].constantize
  end
end
