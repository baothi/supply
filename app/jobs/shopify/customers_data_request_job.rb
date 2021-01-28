module Shopify
  class CustomersDataRequestJob < ApplicationJob
    queue_as :mailers

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      begin
        shop_retailer = Spree::Retailer.find_by(domain: job.option_3)
        email_shop = shop_retailer.email
        orders = Spree::Order.where(retailer_shopify_identifier: job.array_option_1)
        each_order = []
        each_lineitem = []
        product_lineitem = []
        total_order = []
        orders.each do |order|
          id_order = order.retailer_shopify_name
          each_order << id_order

          address = order.shipping_address
          fullname = address.full_name
          each_order << fullname

          customer_email = order.customer_email
          each_order << customer_email

          completed_at = order.completed_at
          each_order << completed_at
          each_order << address.address1
          each_order << address.phone

          order.line_items.each_with_index do |line_item, i|
            product_name = line_item.variant.name
            each_lineitem << product_name

            option_values = line_item.variant.option_values.map(&:name)
            each_lineitem << option_values

            sku = variant.platform_supplier_sku
            each_lineitem << sku

            quantity = line_item.quantity
            each_lineitem << quantity

            product_lineitem << each_lineitem
            each_lineitem.clear
          end
          total_order << product_lineitem
          product_lineitem.clear
          each_order.clear
        end

        # fullname = order.searchable_customer_attributes[:shipping_fullname].blank? ? order.searchable_customer_attributes[:billing_fullname] : order.searchable_customer_attributes[:shipping_fullname]
        RetailerMailer.customers_data_request(email_shop,total_order)

      rescue => e
        puts "#{ex}".red
        job.log_error(e.to_s)
        job.raise_issue!
        return
      end
    end
  end
end
