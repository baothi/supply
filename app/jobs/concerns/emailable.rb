module Emailable
  extend ActiveSupport::Concern
  included do
    require 'open-uri'
  end

  def ensure_supplier_is_emailable
    raise 'Job cannot be nil' if @job.nil?
    raise 'Supplier cannot be nil' if @supplier.nil?
  end

  def ensure_retailer_is_emailable
    raise 'Job cannot be nil' if @job.nil?
    raise 'Retailer cannot be nil' if @retailer.nil?
  end

  def email_results_to_retailer!(subject, message, file_name = nil, file = nil)
    ensure_retailer_is_emailable
    email_teamable!(subject, message, file_name, file)
  end

  def email_results_to_supplier!(subject, message, file_name = nil, file = nil)
    ensure_supplier_is_emailable
    email_teamable!(subject, message, file_name, file)
  end

  def email_results_to_operations!(subject, message, file_name = nil, file = nil)
    email_teamable!(subject, message, file_name, file)
  end

  def email_teamable!(subject, message, file_name = nil, file = nil)
    BulkExportMailer.email_admin(
      subject: subject,
      message: message.html_safe,
      filename: file_name,
      file: file
    ).deliver_now
  end
end
