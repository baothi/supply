module Retailer
  class RetailerGetsFirstSaleJob < ApplicationJob

    queue_as :mailers

    def perform(retailer_id)
      begin
        # SupplierMailer.when_the_stock_items_count_on_hand_is_zero(supplier).deliver_later
        RetailerMailer.retailer_gets_first_sale(retailer_id).deliver_later
      rescue => ex
        puts "#{ex}".red
        job.log_error(ex)
      end
    end
  end
end
