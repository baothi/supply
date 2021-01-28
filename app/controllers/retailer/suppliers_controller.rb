class Retailer::SuppliersController < Retailer::BaseController
  def index
    flash.now[:alert] = 'Please update your plan or contact us for access.'
  end
end
