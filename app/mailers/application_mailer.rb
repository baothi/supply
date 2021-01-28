class ApplicationMailer < ActionMailer::Base
  default from: "TeamUp Support <#{ENV['NOREPLY_EMAIL']}>"
  layout 'mailer'

  add_template_helper(EmailHelper)
end
