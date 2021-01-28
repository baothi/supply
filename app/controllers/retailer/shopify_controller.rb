class Retailer::ShopifyController < ActionController::Base
  include ShopifyInstaller
  include ShopifyAuth
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_as_private

  layout 'registration'

  def initiate; end

  def install
    if ENV['DISABLE_SUPPLIER_AUTHENTICATION'] == 'true'
      return redirect_to root_path
    end

    session[:existing_team_integration] = params[:existing_team_integration]

    login(params[:shop], ENV['SHOPIFY_RETAILER_CALLBACK_URL'])
  end

  def auth
    verify_shopify_request

    login_callback(
      params[:shop],
      retailer_dashboard_path,
      'retailer'
    )

    redirect_to root_path  unless performed?
  end

  def fetch_stock
    render json: {},
           head: :ok,
           content_type: 'application/json'
  end

  def set_as_private
    expires_now
  end
end
