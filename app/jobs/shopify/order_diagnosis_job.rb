module Shopify
  class OrderDiagnosisJob < ApplicationJob
    queue_as :order_export

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        @retailer = Spree::Retailer.find(@job.retailer_id)
        @user = Spree::User.find(@job.option_3)
        raise 'Retailer Required' if @retailer.nil?

        @job.update(total_num_of_records: 1)
        @report = begin
                  if @retailer.initialize_shopify_session! && @job.option_1.present?
                    set_shopify_objects
                    OpenStruct.new ShopifyOrderDiagnosis.new(
                      @shopify_order,
                      @retailer
                    ).perform
                  end
                rescue => ex
                  puts "IMPORT PROCESS ERROR: #{ex}".red
                  nil
                end
        broadcast
      end
    end

    def broadcast
      ActionCable.server.broadcast "job_notifications_#{@user.id}_channel",
                                   content: render_message,
                                   kind: 'order_diagnosis'
    end

    def render_message
      ApplicationController.render(partial: 'retailer/orders/order_report',
                                   locals: { report: @report, retailer: @retailer })
    end

    def set_shopify_objects
      name = @job.option_1
      @all_orders = ShopifyAPI::Order.find(:all, params: { name: name, status: 'any' })

      @shopify_order = nil
      @all_orders.each do |order|
        # puts "Comparing #{order.name} with #{name}".magenta
        if order.name.to_s.casecmp(name.to_s.downcase).zero?
          @shopify_order = order
          break
        end
      end
    end
  end
end
