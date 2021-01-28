module SharedOrdersHelpers
  extend ActiveSupport::Concern
  def fulfill_line_item
    if params[:tracking_number].blank?
      flash[:alert] = 'Please enter a valid tracking number'
      return redirect_back fallback_location: supplier_orders_path
    end

    if params[:line_items].blank?
      flash[:alert] = 'You must select an item(s) to fulfill'
      return redirect_back fallback_location: supplier_orders_path
    end

    fulfill_items_and_add_tracking
    export_fulfillment_to_shopify if @order.retailer_platform == 'shopify'
    flash[:notice] = 'Fulfilled line item(s)'
    redirect_to supplier_order_details_path(id: @order.internal_identifier)
  end

  def import_fulfillment
    order = Spree::Order.find_by(internal_identifier: params[:order_id])
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'orders_import',
      initiated_by: 'user',
      option_1: order.internal_identifier,
      supplier_id: order.supplier_id,
      teamable_type: 'Spree::Supplier',
      teamable_id: order.supplier_id
    )
    ShopifyFulfillmentImportJob.perform_later(job.internal_identifier)
    flash[:notice] = 'Checking for fulfillment update'

    fallback_path = if @team.class.to_s == 'Spree::Supplier'
                      supplier_order_details_path(id: order.internal_identifier)
                    elsif @team.class.to_s == 'Spree::Retailer'
                      retailer_order_details_path(id: order.internal_identifier)
                    end

    redirect_back(fallback_location: fallback_path)
  end

  def cancel_line_item
    # Only allow cancellation by Hingeto users when order is paid for
    # and when not a supplier

    # For now, only admins.
    unless admin_user? || @team.class.to_s == 'Spree::Supplier'
      return redirect_to retailer_orders_path
    end

    @line_item = Spree::LineItem.find_by(internal_identifier: params[:id])
    return redirect_to fallback_path if @line_item.blank?

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

    redirect_back(fallback_location: fallback_path, notice: 'Successfully cancelled line item')
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

    redirect_back(fallback_location: fallback_path)
  end

  private

  def fulfill_items_and_add_tracking
    params[:line_items].each do |li|
      line_item = Spree::LineItem.find_by_internal_identifier(li)
      line_item.fulfill_shipment(params[:tracking_number])
    end
  end

  def export_fulfillment_to_shopify
    export_job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'system',
      option_1: @order.internal_identifier,
      retailer_id: @order.retailer_id
    )
    ShopifyFulfillmentExportJob.perform_later(export_job.internal_identifier)
  end

  def fallback_path
    if @team.class.to_s == 'Spree::Supplier'
      supplier_order_details_path(id: @order.internal_identifier)
    elsif @team.class.to_s == 'Spree::Retailer'
      retailer_order_details_path(id: @order.internal_identifier)
    end
  end
end
