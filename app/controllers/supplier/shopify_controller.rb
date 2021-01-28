class Supplier::ShopifyController < ActionController::Base
  include ShopifyInstaller
  include ShopifyAuth
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'registration'

  def initiate; end

  def install
    if ENV['DISABLE_SUPPLIER_AUTHENTICATION'] == 'true'
      return redirect_to root_path
    end

    session[:existing_team_integration] = params[:existing_team_integration]

    login(params[:shop], ENV['SHOPIFY_SUPPLIER_CALLBACK_URL'])
  end

  def auth
    verify_shopify_request

    login_callback(
      params[:shop],
      supplier_dashboard_path,
      'supplier'
    )

    redirect_to root_path  unless performed?
  end

  # This is a fake endpoint we use in staging environments for providing shopify updates
  def fetch_tracking_numbers
    response = { "message": 'Successfully received the tracking numbers',
                 "success": true }

    respond_to do |format|
      format.any { render json: response, content_type: 'application/json' }
    end
  end

  def fetch_stock
    sku = params[:sku]
    response = if sku.present?
                 { "#{sku}": 1000 }
               else
                 {}
               end
    respond_to do |format|
      format.any { render json: response, content_type: 'application/json' }
    end
  end
end
