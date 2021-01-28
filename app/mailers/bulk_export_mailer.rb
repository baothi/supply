class BulkExportMailer < ApplicationMailer
  default from: "Teamup Support <#{ENV['SUPPLIER_EMAIL']}>"

  def email_admin(subject:, message:, filename:, file:)
    @message = message
    attachments[filename] = file unless file.blank?
    mail to: ENV['OPERATIONS_EMAIL'], subject: subject
  end
end
