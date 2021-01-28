# Preview all emails at http://localhost:3000/rails/mailers/stripe_payment
class JobsPreview < ActionMailer::Preview
  # Preview this email at http://localhost:7000/rails/mailers/jobs/retailer_auto_pay_failure
  def retailer_auto_pay_failure
    JobsMailer.retailer_auto_pay_failure(
      Spree::LongRunningJob.find_by(job_type: 'orders_export')&.id
    )
  end
end
