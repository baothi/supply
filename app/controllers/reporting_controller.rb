class ReportingController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'registration'

  def index; end

  def sales_by_product; end

  def sales_by_sku; end

  def sales_by_period; end

  def sales_by_day; end

  def sales_by_week; end

  def settlement; end
end
