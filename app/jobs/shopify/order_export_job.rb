module Shopify
  class OrderExportJob < ApplicationJob
    include DscoOrderExportCsvGenerator
    queue_as :order_export

    # TODO: Refactor this job to only deal with one order at a time.
    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
        @retailer = Spree::Retailer.find(@job.retailer_id)
        validate_retailer

        @order_ids = @job.option_1.split(',')

        @job.update(total_num_of_records: @order_ids.count)

        @payment_card = @retailer.stripe_cards.where(
          internal_identifier: @job.option_2 # params[:source_identifier]
        ).first

        @order_ids.each do |order_id|
          begin
            order = Spree::Order.find_by(internal_identifier: order_id)
            next if order.shipment_state == 'canceled'

            process_order(order)
            # To mitigate likelihood of API issues but we need a better way to handle
            # i.e. a global message queue for orders
            sleep 0.5
          rescue => e
            @job.log_error(e.to_s)
            @job.raise_issue!
            next
          end
        end
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return
      end
    end

    def process_order(order)
      return if order.nil?

      order.check_country!

      # 1. Check if there's quantity available
      # 2. Make Payment
      # 3. Send Order To Shopify
      pass_country_check = check_country_eligibilities(order)
      pass_costs_check = check_costs(order) if pass_country_check
      pass_quantity_check = check_quantities(order) if pass_costs_check
      paid_for_order = pay_or_skip_payment_for_order(order) if pass_quantity_check
      remit_order(order) if pass_quantity_check && pass_costs_check && paid_for_order
    end

    def validate_retailer
      raise 'Retailer Required' if @retailer.nil?
      raise 'Payment is disabled' if @retailer.disable_payments
    end

    def check_for_line_item_replacement_candidacy_and_execute(order)
      begin
        # No need to try to replace anything if we don't notice anything that needs
        # replacing.
        return if order.get_discontinued_variants_and_valid_counterparts.empty?

        order.replace_discontinued_variants_with_valid_counterpart!
      rescue => ex
        msg = 'Issue replacing variants with valid counterparts!'
        puts "#{msg}".red
        order.update_shopify_logs(msg)
        order.update_shopify_logs(ex)
      end
    end

    # Ensure the orders can be shipped where they're supposed to be
    def check_country_eligibilities(order)
      begin
        order.check_country!
        # Ensure Product is available
        unless order.eligible_for_ordering_based_on_country?
          error_msg = 'We cannot ship this order outside of the US due to supplier restrictions'
          order.update_shopify_logs(error_msg)
          order.raise_issue!
          raise 'International Order for Ineligible supplier found'
        end
        return true
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return false
      end
    end

    # Ensure order has all variant_cost associated with it
    def check_costs(order)
      begin
        order.check_costs!
        error_msg = []
        order.eligible_line_items.each do |line_item|
          if line_item.cost_from_master.nil?
            error_msg <<
              "Missing cost for #{line_item.supplier&.name} "\
                "- #{line_item.variant&.original_supplier_sku}"
            order.update_shopify_logs(error_msg)
          end
        end
        return true if error_msg.empty?

        raise error_msg.join(',')
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        Rollbar.error(e)
        return false
      end
    end

    # For beta - our policy is to only remit when we have quantity for all the line items
    def check_quantities(order)
      begin
        order.check_quantity!

        # This is necessary because of issues where the supplier Shopify variants may change
        # and new ones are created to replace the old ones (hence different IDs)
        check_for_line_item_replacement_candidacy_and_execute(order)
        order.reload

        return true unless order.shopify_order?

        line_items = order.eligible_line_items
        line_items.each do |line_item|
          variant = line_item.variant

          quantity = Spree::Variant.available_quantity(
            retailer: order.retailer,
            platform_supplier_sku: variant.platform_supplier_sku
          )

          results = ShopifyCache::Variant.locate_at_supplier(
            supplier: variant.supplier,
            original_supplier_sku: variant.original_supplier_sku,
            include_unpublished: true
          )

          # supplier_shopify_variant = results[0]
          supplier_shopify_product = results[1]

          # Ensure Product is available
          if supplier_shopify_product.nil? || supplier_shopify_product.published_at.nil?
            error_msg = "This product #{variant.platform_supplier_sku} is no longer available for "
            'sale. We can currently only fulfill entire orders'
            order.update_shopify_logs(error_msg)
            order.raise_issue!
          end

          # Check Quantity / Status
          unless quantity.positive?
            error_msg =
              "There are currently #{quantity} items of #{variant.platform_supplier_sku} in stock "\
              "which means cannot fulfill your requested quantity of #{line_item.quantity}."\
              'We can currently only fulfill entire orders'
            order.update_shopify_logs(error_msg)
            order.raise_issue!
          end
        end
        return true
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return false
      end
    end

    def pay_or_skip_payment_for_order(order)
      return skip_payment_for_order(order) if @retailer.setting_skip_payment_for_orders

      pay_for_order(order)
    end

    def skip_payment_for_order(order)
      order.remit_payment!
      amount = 0
      charge = OpenStruct.new(
        captured: true, paid: true, amount: amount, id: "skip-payment-#{order.id}"
      )
      order.make_payment(charge, @payment_card)
      order.create_invoice
      order.update_payment_state!
      order.update_shopify_logs('Payment was skipped for this order')
      true
    rescue => e
      @job.log_error(e.to_s)
      @job.raise_issue!
      false
    end

    def pay_for_order(order)
      begin
        order.remit_payment!
        order.apply_credit_discount! if @job.option_3 == '1'
        stripe_customer = @retailer.stripe_customer
        card = @payment_card.card_identifier

        amount = order.price_after_discount
        description = "MXED Retailer #{@retailer.name} Order #{order.number}"
        charge = StripeService.charge_stripe_customer(
          stripe_customer,
          amount,
          description,
          card,
          order.id
        )
        post_process_charge(charge, order)
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return false
      end
      true
    end

    def post_process_charge(charge, order_object)
      if charge.captured
        payment = order_object.make_payment(charge, @payment_card)
        if payment.completed?
          order_object.create_invoice
          order_object.update_payment_state!
          order_object.update_shopify_logs('Your Payment was successful')
        else
          order_object.update_shopify_logs('Payment was not successful')
          order_object.raise_issue!
          raise 'Payment was not successful'
        end
      else
        order_object.update_shopify_logs(charge.error)
        order_object.raise_issue!
        raise "Error: #{charge.error}"
      end
    end

    def remit_order(order)
      send("remit_#{order.supplier_platform}_order", order)
    end

    def remit_shopify_order(order)
      begin
        shopify = Shopify::Export::Order.new
        status = shopify.perform(order.internal_identifier)
        @job.update_status(status)
        if status && @job.setting_auto_paid
          order.update(auto_paid_at: Time.current)
        end
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return
      end

      @job.log_error(shopify.errors)
      @job.update_log(shopify.logs)
    end

    def remit_dsco_order(order)
      order.remit_order!
      raw_content = generate_dsco_export_file([order.id])
      @job.raise_issue unless raw_content.present?
      file = StringIO.new(raw_content)
      filename = "#{order.supplier.slug}_dsco_order_export_#{order.number}.csv"
      @job.output_csv_file = file
      @job.output_csv_file.instance_write(:content_type, 'text/csv')
      @job.output_csv_file.instance_write(:file_name, filename)
      @job.save!

      begin
        file_name = "Purchase_Order_single_#{order.number}.csv"
        url = if Rails.env.development?
                "#{Rails.root}/public#{@job.output_csv_file.url(:original, timestamp: false)}"
              else
                @job.output_csv_file.url
              end
        contents = open(url).read

        file = Supply::TemporaryFileHelper.temp_file(contents, 'csv')
        order.complete_remittance! if Dsco::Ftp.new.upload(file, file_name)
      rescue => e
        @job.log_error(e.to_s)
      end
    end

    # TODO: This is a hack. This should be updated to be an SFTP method
    # that happens to use SSH (versus hard coded like this)
    def remit_revlon_order(order)
      order.remit_order!
      begin
        ro = Revlon::Outbound::PurchaseOrderService.new(orders: [order]).perform
        if ro.successful?
          order.update_shopify_logs('Successfully remitted order to JCB')
          order.complete_remittance!
        else
          order.update_shopify_logs('Unable to remit order to JCB')
        end
      rescue => ex
        Rollbar.error(ex)
        puts "#{ex}".red
        @job.log_error(ex.to_s)
      end
    end
  end
end
