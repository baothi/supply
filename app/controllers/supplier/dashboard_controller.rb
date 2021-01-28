class Supplier::DashboardController < Supplier::BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  def index
    @orders = Spree::Order.where(supplier_id: current_supplier.id)
    @products = Spree::Product.where(supplier_id: current_supplier.id)
  end
end
