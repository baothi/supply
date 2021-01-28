class JobsMailer < ApplicationMailer
  default from: "TeamUp <#{ENV['RETAILER_EMAIL']}>"

  def retailer_auto_pay_failure(job_id)
    job = Spree::LongRunningJob.find_by(id: job_id)
    @order = Spree::Order.find_by(internal_identifier: job.option_1)
    @retailer = @order&.retailer
    return unless @order.present? && @retailer.present?

    @error_msg = job.error_log
    mail to: @retailer.email,
         subject: 'Auto Payment Error',
         bcc: ENV['OPERATIONS_EMAIL']
  end

  def shopify_csv_upload_success(job_id)
    job = Spree::LongRunningJob.find_by(id: job_id)
    @supplier = Spree::Supplier.find_by(id: job.supplier_id)

    mail to: ENV['OPERATIONS_EMAIL'],
         from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>",
         subject: "Price uploaded for supplier - #{@supplier.name}"
  end

  def shopify_csv_upload_error(job_id)
    job = Spree::LongRunningJob.find_by(id: job_id)
    @supplier = Spree::Supplier.find_by(id: job.supplier_id)

    @error_msg = job.error_log
    mail to: ENV['OPERATIONS_EMAIL'],
         from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>",
         subject: "Error Occurred while uploading price for supplier  - #{@supplier.name}"
  end

  def notify_job_completion(job, file, subject = :Report)
    @job = job
    @user = @job.user
    # If we detect a hash, we know there's multiple files
    if file.present? && file.is_a?(Hash)
      file.each do |key, value|
        attachments[key.to_s] = value
      end
    else
      attachments[@job.output_csv_file_file_name] = file
    end
    # email = @user.present? ? @user.email : ENV['OPERATIONS_EMAIL']
    email = ENV['OPERATIONS_EMAIL']
    mail to: email, subject: "#{subject} - #{DateTime.now}"
  end
end
