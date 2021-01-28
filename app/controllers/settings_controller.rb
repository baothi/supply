class SettingsController < Supplier::BaseController
  include ShopifyInstaller
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  def index; end

  def shopify_settings; end

  def shopify_login
    login(
      params[:brand][:store_name],
      'http://localhost:3000/settings/shopify/login/callback',
      'https://bio-hingeto.herokuapp.com/settings/shopify/login/callback'
    )
  end

  def shopify_login_callback
    unless params[:code]
      return redirect_to settings_shopify_settings_path, error: 'Could not Authenticate'
    end

    login_callback(params[:shop], settings_shopify_settings_path)
  end

  def send_email_confirmation_request; end

  def shipping; end

  def accounting; end

  def user_settings; end

  def billing_information; end
end
