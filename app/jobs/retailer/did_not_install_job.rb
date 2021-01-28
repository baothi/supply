class Retailer::DidNotInstallJob < ApplicationJob

  queue_as :mailers

  def perform(job_id)
    begin

      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?
      uninstalled_emails = job.array_option_1
      uninstalled_emails.each do |email|
        RetailerMailer.did_not_install_app(email).deliver_later
      end
    rescue => ex
      puts "#{ex}".red
      job.log_error(ex)
    end
  end
end
