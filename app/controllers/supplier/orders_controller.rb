class Supplier::OrdersController < Supplier::BaseController
  include SharedOrdersHelpers

  before_action :ensure_allowed_error_reporting, only: :reported
  before_action :set_order, only: %i(details report_decision fulfill_line_item)

  def index
    @orders = Spree::Order.paid.filter(
      current_supplier, params[:status], params[:q]
    ).order('completed_at desc').page(params[:page]).per(10)
  end

  def reported
    @orders =
      current_supplier.orders.unscoped.paid.is_reported.filter_by_attributes(params[:q]).
      order('updated_at desc').page(params[:page]).per(10)
  end

  def report_decision
    @order_issue = @order.order_issue_report
    case params[:commit]
    when 'Approve'
      validate_and_set_credit_amount
      @order_issue.resolve_as_supplier!
    when 'Decline'
      @order_issue.decline_reason = params[:reason]
      if @order_issue.decline!
        flash[:notice] = 'Resolved!'
      else
        flash[:error] = 'Could not decline'
      end
    end
    redirect_back fallback_location: supplier_orders_reported_path
  end

  private

  def set_order
    @order = Spree::Order.find_by(internal_identifier: params[:order_id] || params[:id])
  end

  def validate_and_set_credit_amount
    amount = params[:amount].to_f
    if @order.grand_total >= amount
      @order_issue.amount_credited = amount
      @order_issue.save
      flash[:notice] = "Resolved! The retailer has been credited with $#{amount}"
      return true
    end
    flash[:error] = 'You cannot credit amount more than the order total'
  end

  def ensure_allowed_error_reporting
    redirect_to supplier_dashboard_path unless current_supplier.allow_order_issue_reporting
  end
end
