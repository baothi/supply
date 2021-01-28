class Retailer::OrdersController < Retailer::BaseController
  include EnsureStrippable
  include SharedOrdersHelpers
  before_action :set_cards, only: %i(index samples details archived bulk_payment batch_action)
  before_action :set_global_order, only: %i(remit_to_shopify remit_to_dsco edit_line_items
                                            replace_line_items replace_discontinued_line_items
                                            fulfill_line_item cancel_order)
  before_action :set_per_page, only: %i(index samples archived reported)

  def index
    @orders = Spree::Order.unarchived.non_sample_orders.filter(
      current_retailer, params[:status], params[:q]
    ).
              order('completed_at desc').page(params[:page]).per(@per_page)
  end

  def samples
    @orders =
      Spree::Order.sample_orders.filter(current_retailer, params[:status], params[:q]).
      search(params[:keyword], current_retailer.id).
      order('completed_at desc').page(params[:page]).per(@per_page)
  end

  def archived
    @orders =
      Spree::Order.archived.filter(current_retailer, params[:status], params[:q]).
      order('archived_at desc').page(params[:page]).per(@per_page)
    render :index
  end

  def reported
    @orders =
      current_retailer.orders.is_reported.filter_by_attributes(params[:q]).
      order('updated_at desc').page(params[:page]).per(@per_page)
  end

  def details
    @order = Spree::Order.find_by(internal_identifier: params[:id])
    redirect_to retailer_orders_path, alert: 'Order not found' unless @order.present?
  end

  def new_card
    return unless params[:token].present?

    if StripeService.add_card_to_customer(current_retailer.stripe_customer, params[:token])
      @cards = @retailer.stripe_cards
      @selected_card = current_retailer.stripe_cards.last
    else
      @error = 'Card could not be added'
    end

    respond_to do |format|
      format.js { render 'new_card' }
    end
  end

  def find_shopify_order
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'approval',
      initiated_by: 'user',
      retailer_id: @retailer.id,
      option_1: params[:shopify_order_number],
      option_3: current_spree_user.id # To set action cable connection
    )
    Shopify::ManualOrderFinderJob.perform_later(job.internal_identifier)

    respond_to do |format|
      format.js
    end
  end

  def manual_import
    @shopify_order = nil
    @line_items = nil
    begin
      if current_retailer.initialize_shopify_session! && params[:shopify_order_number].present?
        # name = "##{params[:shopify_order_number]}"
        name = params[:shopify_order_number]
        @shopify_order = ShopifyAPI::Order.find(:all, params: { name: name, status: 'any' }).first
        @line_items = @shopify_order.line_items if @shopify_order
        @variants = Spree::Variant.where(is_master: false)
        # flash[:notice] = 'Select matching variants'
        flash[:alert] = 'This is a fulfilled order. Proceed with caution!' if
            @shopify_order.fulfillment_status == 'fulfilled'
      end
    rescue
      flash[:alert] = 'Could not find shopify order'
    end
  end

  def manual_variant_finder
    @line_item_selector = params[:line_item_id]
    @variant = Spree::Variant.find_by(internal_identifier: params[:variant_id])
  end

  def order_import
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'approval',
      initiated_by: 'user',
      retailer_id: @retailer.id,
      option_1: params[:shopify_order_number],
      option_2: nil,
      option_3: current_spree_user.id, # To set action cable connection
      hash_option_1: params.to_hash # using option_9 because it is serialized and can store a hash
    )

    Shopify::ManualOrderImportJob.perform_later(job.internal_identifier)

    respond_to do |format|
      format.js
    end
  end

  def all_cards
    @cards = current_retailer.stripe_cards
    respond_to do |format|
      format.js { render 'all_cards' }
    end
  end

  def clear_errors
    order = Spree::Order.find_by!(internal_identifier: params[:id])
    order.reset_remittance!
    notice = I18n.t('successfully_cleared_order_errors',
                    number: order.retailer_shopify_order_number)
    redirect_to retailer_orders_path,
                notice: notice
  end

  def reset_remittance
    order = Spree::Order.find_by!(internal_identifier: params[:order_id])

    if order.has_payments_or_is_paid?
      redirect_to retailer_order_details_path(
        id: order.internal_identifier
      ), alert: 'This order is already paid for.'
      return
    end

    order.reset_remittance!
    notice = I18n.t('successfully_cleared_order_errors',
                    number: order.retailer_shopify_order_number)

    redirect_to retailer_order_details_path(
      id: order.internal_identifier
    ), notice: notice
    nil
  end

  def delete_order
    unless admin_user?
      redirect_to retailer_order_details_path(
        id: order.internal_identifier
      ), alert: 'You are not allowed to perform this action.'
      return
    end

    order = Spree::Order.find_by!(internal_identifier: params[:order_id])
    if order.has_payments_or_is_paid? || order.successfully_sent_order?
      redirect_to retailer_order_details_path(
        id: order.internal_identifier
      ), alert: 'Cannot deleted paid or remitted orders. Please contact technical'\
                              ' support to remove this order'
      return
    end

    number = order.retailer_shopify_order_number
    order.destroy
    notice = "Order #{number} has been destroyed."

    redirect_to retailer_orders_path, notice: notice
    nil
  end

  def import
    if invalid_time_period_selected?
      redirect_to retailer_orders_path,
                  alert: 'Please select a value for both the from & to for importing orders'
      return
    end

    if params[:default_duration].blank?
      to_date = DateTime.strptime(params[:to_date], '%Y-%m-%d')
      from_date = DateTime.strptime(params[:from_date], '%Y-%m-%d')

      if to_date < from_date
        redirect_to retailer_orders_path, alert: 'The from date cannot be after the to date'
        return
      end
    end

    from_date, to_date = set_date_range
    # from_date = from_date - 1.days unless from_date.nil?
    # to_date = to_date + 1.days unless to_date.nil?

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      option_1: 'mass',
      option_2: from_date,
      option_3: to_date,
      setting_attempt_auto_pay: params[:attempt_auto_pay],
      retailer_id: @retailer.id,
      supplier_id: nil,
      teamable_type: 'Spree::Retailer',
      teamable_id: @retailer.id
    )
    ShopifyOrderImportJob.perform_later(job.internal_identifier)
    redirect_to retailer_orders_path, notice: 'Importing Orders for selected range'
  end

  def pay
    if ENV['DISABLE_ORDER_REMITTANCE'] == 'yes'
      flash[:alert] = 'Order Remittance has been temporarily disabled. Please check back in 15 minutes.'
      return redirect_to retailer_orders_path
    end

    orders = Spree::Order.where(internal_identifier: params[:order_ids].split(','))
    initiate_order_export(orders)

    if orders.count == 1
      flash[:notice] = "Payment Initiated for Order ##{orders.first.number}"
    else
      flash[:notice] = 'Payment Initiated for orders'
      return redirect_to retailer_orders_path
    end
    redirect_back(fallback_location: retailer_orders_path)
  end

  def set_free_shipping
    order = Spree::Order.find_by(internal_identifier: params[:order_id])

    unless order.safe_to_modify?
      redirect_to retailer_order_details_path(
        id: order.internal_identifier
      ), alert: 'Cannot modify shipping for paid/remitted orders'
      return
    end

    order.remove_shipping!
    order.set_dropshipping_totals!
    flash[:notice] = 'Shipping has been removed from this order'

    redirect_back(fallback_location: retailer_orders_path)
  end

  def update_order_risks
    order = Spree::Order.find_by(internal_identifier: params[:order_id])
    order.redownload_order_risks(current_spree_user)

    flash[:notice] = 'Order risks are being updated'
    redirect_back(fallback_location: retailer_orders_path)
  end

  def remove_shipping_and_set_cost
    order = Spree::Order.find_by(internal_identifier: params[:order_id])

    unless order.safe_to_modify?
      redirect_to retailer_order_details_path(
        id: order.internal_identifier
      ), alert: 'Cannot modify shipping for paid/remitted orders'
      return
    end

    order.remove_shipping!
    cost = params[:amount_in_cents].to_f / 100
    order.set_line_item_costs!(cost)
    flash[:notice] = "Shipping costs removed. Line Items set to $#{cost}"

    redirect_back(fallback_location: retailer_orders_path)
  end

  def switch_card
    @selected_card = current_retailer.stripe_cards.where(
      internal_identifier: params[:internal_identifier]
    ).first

    respond_to do |format|
      format.js { render 'switch_card' }
    end
  end

  def remit_to_shopify
    begin
      unless @order.paid?
        redirect_to retailer_order_details_path(
          id: @order.internal_identifier
        ), alert: 'Payment is needed before remittance.'
        return
      end

      if @order.successfully_sent_order?
        redirect_to retailer_order_details_path(
          id: @order.internal_identifier
        ), alert: 'This order has already been sent!'
        return
      end

      if @order.shipment_state == 'canceled'
        redirect_to retailer_order_details_path(id: @order.internal_identifier),
                    alert: 'This order has been canceled'
        return
      end

      prep_order_for_remittance

      shopify = Shopify::Export::Order.new
    rescue => e
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), alert: e
      return
    end

    result = shopify.perform(@order.internal_identifier)

    # if shopify.connected
    #   shopify.perform(params[:order_id])
    # else
    #   redirect_to retailer_order_details_path(
    #     id: @order.internal_identifier
    #   ), alert: 'Unable to connect to Shopify'
    #   return
    # end

    if result
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), notice: 'Remitted to Shopify.'
    else
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), alert: 'There was an issue remitting this order. Please refer to the logs'
    end
    nil
  end

  def remit_to_dsco
    unless @order.paid?
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), alert: 'Payment is needed before remittance.'
      return
    end

    if @order.successfully_sent_order?
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), alert: 'This order has already been sent!'
      return
    end

    job = Spree::LongRunningJob.new(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      option_1: order.internal_identifier
    )

    if job.save
      Dsco::Order::Remittance.perform_later(job.internal_identifier)
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), notice:  'Remitted to DSCO.'
    else
      redirect_to retailer_order_details_path(
        id: @order.internal_identifier
      ), alert: 'There was an issue remitting this order. Please refer to the logs'
    end
  end

  def replace_discontinued_line_items
    begin
      @order.replace_discontinued_variants_with_valid_counterpart!
      flash[:notice] = 'Line items replaced with counterparts'
    rescue => e
      flash[:alert] = e.to_s
    end
    redirect_to retailer_order_details_path(id: @order.internal_identifier)
  end

  def export_fulfillment
    order = Spree::Order.find_by(internal_identifier: params[:order_id])
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      option_1: order.internal_identifier,
      retailer_id: current_retailer.id
    )
    ShopifyFulfillmentExportJob.perform_later(job.internal_identifier)
    redirect_to retailer_order_details_path(
      id: order.internal_identifier
    ), notice: 'Uploading fulfillments'
  end

  def batch_action
    case params[:batch_action]
    when 'Archive Orders'
      archive_orders(params[:order_ids])
    when 'Unarchive Orders'
      unarchive_orders(params[:order_ids])
    when 'Pay for Orders'
      bulk_payment(params[:order_ids])
    end
  end

  def open_issue_report_modal
    @order = Spree::Order.find_by(internal_identifier: params[:id])
  end

  def save_order_issue_report
    report = Spree::OrderIssueReport.new(order_issue_report_params)
    if report.save
      redirect_back(
        fallback_location: retailer_orders_path,
        notice: I18n.t('order_issue_report_received')
      ) and return
    end

    redirect_back(
      fallback_location: retailer_orders_path,
      alert: "Error: #{report.errors.full_messages.join('. ')}"
    )
  end

  def diagnose
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'approval',
      initiated_by: 'user',
      retailer_id: @retailer.id,
      option_1: params[:shopify_order_number],
      option_2: nil,
      option_3: current_spree_user.id, # To set action cable connection
    )

    Shopify::OrderDiagnosisJob.perform_later(job.internal_identifier)

    respond_to do |format|
      format.js
    end
  end

  def edit_line_items; end

  def replace_line_items
    if @order.paid?
      flash[:alert] = 'Cannot replace line items for paid order'
      return redirect_to retailer_order_details_path(id: @order.internal_identifier)
    end
    begin
      line_items = @order.line_items
      line_items.each do |item|
        next if params[item.id.to_s].blank?

        item.variant = Spree::Variant.find_by(internal_identifier: params[item.id.to_s])
        item.save!
      end
      @order.post_process_order!
      flash[:notice] = 'Successful'
    rescue => e
      flash[:alert] = e.to_s
    end
    redirect_to retailer_order_details_path(id: @order.internal_identifier)
  end

  def cancel_line_item
    # Only allow cancellation by Hingeto users when order is paid for
    # and when not a supplier

    # For now, only admins.
    return redirect_to retailer_orders_path unless admin_user?

    @line_item = Spree::LineItem.find_by(internal_identifier: params[:id])
    return redirect_to retailer_orders_path if @line_item.blank?

    @order = @line_item.order

    if @line_item.shipped?
      redirect_with_message('Error. We cannot cancel line item that is shipped')
      return
    end

    @line_item.mark_as_canceled!

    # @line_item.notify_suppliers_and_retailers_of_line_item_cancellation!(@team_type)

    # Now update order level shipment
    if @order.present?
      unless @order.paid?
        @order.post_process_order!
      end
      @order.updater.update_shipment_state
      @order.save
    end

    @order.notify_retailers_of_cancellation!('retailer', [@line_item.id])

    redirect_to retailer_order_details_path(
      id: @order.internal_identifier,
      internal_identifier: @order.internal_identifier
    ), notice: 'Successfully cancelled line item'
  end

  def refund_line_item
    return redirect_to retailer_orders_path unless admin_user?

    @line_item = Spree::LineItem.find_by(internal_identifier: params[:id])
    return redirect_to retailer_orders_path if @line_item.blank?

    response = @line_item.issue_full_refund!(
      allow_fulfilled_orders: true,
      reason: 'Initiated by Admin'
    ) # TODO: Collect reason from UI

    @order = @line_item.order

    # @order.notify_suppliers_and_retailers_of_cancellation!(@team_type)

    if response.success
      flash[:notice] = response.message
    else
      flash[:alert] = response.message
    end

    redirect_to retailer_order_details_path(
      id: @order.internal_identifier,
      internal_identifier: @order.internal_identifier
    )
  end

  def issue_full_refund
    order = Spree::Order.find_by(internal_identifier: params[:order_id])
    response = order.issue_full_refund!(
      allow_fulfilled_orders: true,
      reason: 'Initiated by Admin'
    ) # TODO: Collect reason from UI

    if response.success
      flash[:notice] = response.message
    else
      flash[:alert] = response.message
    end

    redirect_back(fallback_location: retailer_orders_path)
  end

  def cancel_order
    return redirect_to retailer_orders_path unless admin_user?

    if @order.shipped?
      redirect_with_message(I18n.t('orders.cannot_cancel_order_shipped'))
      return
    end

    @order.cancel_entire_order!

    @order.notify_retailers_of_cancellation!(@team_type)

    redirect_to retailer_order_details_path(
      id: @order.internal_identifier,
      internal_identifier: @order.internal_identifier
    ), notice: 'Successfully cancelled all line items!'
  end

  private

  def redirect_with_message(msg)
    redirect_to retailer_order_details_path(
      internal_identifier: @order.internal_identifier
    ), alert: msg
  end

  def order_issue_report_params
    params.require(:order_issue_report).permit(:order_id, :description, :image1, :image2)
  end

  def set_global_order
    @order = Spree::Order.find_by(internal_identifier: params[:order_id])
    redirect_to retailer_orders_path, alert: 'Order not found' unless @order.present?
  end

  def prep_order_for_remittance
    # We simulate these events to ensure the proper state
    # machine progression
    @order.reset_remittance!
    @order.schedule_remittance!
    @order.check_country!
    @order.check_costs!
    @order.check_quantity!
    @order.remit_payment!
  end

  def invalid_time_period_selected?
    (params[:to_date].blank? || params[:to_date].blank?) && params[:default_duration].blank?
  end

  def initiate_order_export(orders)
    orders.map(&:schedule_remittance!)
    order_ids = orders.pluck(:internal_identifier).join(',')
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      option_1: order_ids,
      option_2: params[:source_identifier],
      option_3: params[:apply_credit],
      retailer_id: current_retailer.id,
      supplier_id: nil,
      teamable_type: nil,
      teamable_id: nil
    )
    Shopify::OrderExportJob.perform_later(job.internal_identifier)
  end

  def set_cards
    @cards = current_retailer.stripe_cards
    @selected_card = current_retailer.stripe_customer.default_card unless @cards.blank?
  end

  def time_format
    '%FT%T%:z'
  end

  def set_date_range
    return custom_range unless params[:default_duration].present?

    case params[:default_duration]
    when 'today'
      today_time_period
    when 'this_week'
      this_week_time_period
    when 'this_month'
      this_month_time_period
    end
  end

  def today_time_period
    [DateTime.now.beginning_of_day.strftime(time_format),
     DateTime.now.end_of_day.strftime(time_format)]
  end

  def this_week_time_period
    [DateTime.now.beginning_of_week.strftime(time_format),
     DateTime.now.end_of_day.strftime(time_format)]
  end

  def this_month_time_period
    [DateTime.now.beginning_of_month.strftime(time_format),
     DateTime.now.end_of_day.strftime(time_format)]
  end

  def custom_range
    to_date = DateTime.strptime(params[:to_date], '%Y-%m-%d')
    from_date = DateTime.strptime(params[:from_date], '%Y-%m-%d')

    [from_date.strftime(time_format), to_date.strftime(time_format)]
  end

  def set_shopify_objects
    name = "##{params[:shopify_order_number]}"
    @shopify_order = ShopifyAPI::Order.find(:all, params: { name: name, status: 'any' }).first
    @line_items = @shopify_order.line_items if @shopify_order
    @line_item_variants = {}
    @line_items.each do |item|
      @line_item_variants[item.id.to_s] = params[item.id.to_s] unless params[item.id.to_s].blank?
    end
  end

  def archive_orders(order_ids)
    if current_retailer.orders.where(
      internal_identifier: order_ids
    ).update_all(archived_at: Time.now)
      flash[:notice] = 'Orders Archived'
    else
      flash[:alert] = 'Could not archive orders'
    end
    redirect_back(fallback_location: retailer_orders_path)
  end

  def unarchive_orders(order_ids)
    if current_retailer.orders.unscoped.where(
      internal_identifier: order_ids
    ).update_all(archived_at: nil)
      flash[:notice] = 'Orders Unarchived'
    else
      flash[:alert] = 'Could not unarchive orders'
    end
    redirect_back(fallback_location: retailer_orders_path)
  end

  def bulk_payment(order_ids)
    if current_retailer.disable_payments
      flash[:alert] =
        'You are not allowed to pay for orders due to an issue with you account. '\
        'Please contact us'
      return redirect_back(fallback_location: retailer_orders_path)
    end
    @orders = Spree::Order.unpaid.where(internal_identifier: order_ids)
    @orders = @orders.select(&:orderable?)
    @total = @orders.reduce(0) { |total, order| total + order.grand_total }

    render :bulk_payment
  end

  def set_per_page
    if params[:per_page].present?
      session[:per_page] = params[:per_page].to_i > 100 ? '100' : params[:per_page]
    end
    @per_page = session[:per_page] || '10'
  end
end
