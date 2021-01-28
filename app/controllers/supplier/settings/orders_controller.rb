class Supplier::Settings::OrdersController < Supplier::BaseController
  def index; end

  # def retailer_auto_payment_setting
  #   if current_retailer.update(order_auto_payment: params[:auto_pay])
  #     flash[:notice] = 'Auto paymemnt setting updated!'
  #   else
  #     flash[:alert] = 'Error update auto payment settings'
  #   end
  #
  #   redirect_to action: :index
  # end
end
