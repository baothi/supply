class OperationsMailer < ApplicationMailer
  default from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>"

  def email_legal_proof(retailer, message, file = '')
    @retailer = retailer
    @message = message

    attachments['legal_proof.pdf'] = file unless file.blank?

    mail to: ENV['OPERATIONS_EMAIL'],
         subject: "Documentation for #{retailer.name}"
  end

  def email_admin(subject, message, file = '')
    @message = message

    attachments['file.csv'] = file unless file.blank?

    mail to: ENV['OPERATIONS_EMAIL'],
         subject: subject
  end

  def email_admin_with_attachment(subject:, message:, file_path:, file_name:)
    @message = message

    # Reuse email admin view
    attachments[file_name] = File.read(file_path) unless
        file_path.blank?

    mail(to:  ENV['OPERATIONS_EMAIL'],
         subject: subject) do |format|
      format.html { render 'email_admin' }
    end
  end

  def generic_email_to_admin(subject, message)
    @message = message
    @subject = subject

    mail to: ENV['OPERATIONS_EMAIL'],
         subject: subject
  end
end
