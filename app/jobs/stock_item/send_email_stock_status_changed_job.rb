module StockItem
  class SendEmailStockStatusChangedJob < ApplicationJob

    queue_as :mailers

    def perform(job_id)
      begin
        job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        job.initialize_and_begin_job! unless job.in_progress?
        product_id = (job.option_1).to_i
        retailers = Spree::ProductListing
                        .where(product_id: product_id)
                        .distinct
                        .pluck(:retailer_id)

        retailers += Spree::Favorite
                        .where(product_id: product_id)
                        .distinct
                        .pluck(:retailer_id)

        retailers = retailers.uniq

        return if retailers.empty?
        bcc_email = []
        product = Spree::Product.find_by_id(product_id)
        retailers.each do |retailer_id|
          retailer = Spree::Retailer.find_by_id(retailer_id)
          next unless retailer.app_name == 'teamup'
          bcc_email << retailer.email
        end
        bcc_email = bcc_email.uniq

        RetailerMailer.send_email_stock_status_changed(bcc_email,product&.name,product&.internal_identifier,job.option_2).deliver_later
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex)
      end
    end
  end
end
