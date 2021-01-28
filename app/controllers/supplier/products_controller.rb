class Supplier::ProductsController < Supplier::BaseController
  before_action :set_product, only: :details

  def index
    @statuses = %i(all) + Spree::Product.aasm.states.map(&:name)
    @products = current_supplier.products.page(params[:page]).per(10).filter(params[:filter_by])
  end

  def details
    # @options = @product.option_names_by_order
  end

  def set_product
    @product = Spree::Product.find_by(internal_identifier: params[:id])
    return if @product.present?

    flash[:alert] = 'Product not found'
    redirect_to action: :index
  end
end
