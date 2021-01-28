module Shopify
  class ManualOrderFinderJob < ApplicationJob
    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        @retailer = Spree::Retailer.find(@job.retailer_id)
        @user = Spree::User.find(@job.option_3)

        @job.update(total_num_of_records: 1)

        find_shopify_order_and_line_items

        @job.update_status(@shopify_order.present?)
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
      end
      broadcast
      @retailer.destroy_shopify_session!
    end

    def broadcast
      ActionCable.server.broadcast "job_notifications_#{@user.id}_channel",
                                   content: render_message,
                                   kind: 'manual_order_finder'
    end

    def render_message
      ApplicationController.render(partial: 'retailer/orders/import_order',
                                   locals: { line_items: @line_items,
                                             shopify_order: @shopify_order,
                                             retailer: @retailer })
    end

    def find_shopify_order_and_line_items
      begin
        if @retailer.initialize_shopify_session! && @job.option_1.present?
          # name = "##{@job.option_1}"
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

          @line_items = @shopify_order.line_items if @shopify_order
        end
      rescue
        nil
      end
    end
  end
end
