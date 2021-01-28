class ProductsController < BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  before_action :set_images

  def index; end

  def inventory; end

  def new; end

  def test; end

  def show
    render 'new'
  end

  def image_upload
    # render text: "Success", status: 200
    render json: {}, status: :ok
  end
end
