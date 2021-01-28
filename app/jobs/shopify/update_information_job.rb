module Shopify
  class UpdateInformationJob < ApplicationJob
    queue_as :shopify_import

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      retailer = Spree::Retailer.find_by(id: job.retailer_id)

      begin
        retailer.init

        shop = CommerceEngine::Shopify::Shop.current
        retailer.address1 = shop.address1
        retailer.address2 = shop.address2
        retailer.city = shop.city
        retailer.state = shop.province_code
        retailer.country = shop.country
        retailer.zipcode = shop.zip
        retailer.phone = shop.phone

        retailer.shop_owner = shop.shop_owner

        retailer.save!
      rescue => e
        puts e
      end
    end
  end
end
