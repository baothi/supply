module Products
  class SendMailDeactivatedProductJob < ApplicationJob
    queue_as :mailers

    def perform(job_id)
      begin
        job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job! unless job.in_progress?
        bcc_email = []
        job.array_option_1.each do |product_retailer|
          product_id = product_retailer.shift
          product_retailer.each do |deactivated|
            retailer = Spree::Retailer.find_by_id(deactivated)
            unless bcc_email.include? retailer.email || retailer.app_name != 'teamup'
              bcc_email << retailer.email
            end
          end
          product = Spree::Product.find_by_id(product_id)
          product_name = product.name
          product_internal_identifier = product.internal_identifier

          RetailerMailer.send_mail_deactivated_product(product_internal_identifier,product_name,bcc_email).deliver_later
          bcc_email.clear
        end
      rescue => ex
        puts "#{ex}".red
      end
    end
  end
end
