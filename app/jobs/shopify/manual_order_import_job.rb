module Shopify
  class ManualOrderImportJob < ApplicationJob
    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        @retailer = Spree::Retailer.find(@job.retailer_id)
        @user = Spree::User.find(@job.option_3)
        raise 'Retailer Required' if @retailer.nil?

        @job.update(total_num_of_records: 1)

        @orders = begin
                  if @retailer.initialize_shopify_session! && @job.option_1.present?
                    set_shopify_objects

                    Shopify::Import::GhostOrder.new(
                      @shopify_order, @line_items, @line_item_variants, @retailer
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
                                   kind: 'manual_order_import'
    end

    def render_message
      ApplicationController.render(partial: 'retailer/orders/manual_order_import_notice',
                                   locals: { orders: @orders, order_name: @job.option_1 })
    end

    def set_shopify_objects
      name = @job.option_1
      params = @job.hash_option_1
      @all_orders = ShopifyAPI::Order.find(:all, params: { name: name, status: 'any' })

      # puts "about to look for : #{name}".yellow

      # puts 'Found these orders: '.yellow
      # puts @all_orders

      @shopify_order = nil
      @all_orders.each do |order|
        # puts "Comparing #{order.name} with #{name}".magenta
        if order.name.to_s.casecmp(name.to_s.downcase).zero?
          @shopify_order = order
          break
        end
      end

      raise 'Shopify Order not found' if @shopify_order.nil?

      @line_items = @shopify_order.line_items if @shopify_order
      @line_item_variants = {}
      @line_items.each do |item|
        @line_item_variants[item.id.to_s] = params[item.id.to_s] unless params[item.id.to_s].blank?
      end
    end
  end
end
