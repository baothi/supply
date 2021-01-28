class Retailer::IntegrationsController < Retailer::BaseController
  skip_before_action :confirm_onboarded?

  before_action :set_shopify_session, only: %i(shopify_login shopify_login_callback)

  def index; end

  def shopify
    @shopify_credential = Spree::ShopifyCredential.find_or_initialize_by(
      teamable_id: current_retailer.id,
      teamable_type: 'Spree::Retailer'
    )
  end

  def update_shopify
    @shopify_credential = Spree::ShopifyCredential.find_or_initialize_by(
      retailer_id: params[:retailer_id]
    )

    flash[:error] = 'Credentials could not be saved, an error occured' unless
    if @shopify_credential.update_attributes(shopify_credential_params.merge(kind: 'credential'))
    end
    redirect_to retailer_integrations_shopify_path
  end

  def shopify_login
    @shopify_credential.update_attributes!(shopify_credential_params)
    shopify_session = ShopifyAPI::Session.new(
      domain: @shopify_credential.store_url,
      token: @shopify_credential.access_token,
      api_version: ENV['SHOPIFY_API_VERSION']
    )
    host = request.host

    host = host + ':3000' if ENV['DROPSHIPPER_ENV'] == 'development'
    redirect_url = "http://#{host}/retailer/integrations/shopify/login/callback"

    permission_url = shopify_session.create_permission_url(
      Spree::ShopifyCredential::SCOPE,
      redirect_url
    )

    redirect_to permission_url
  end

  def shopify_login_callback
    unless params[:code]
      return redirect_to retailer_integrations_shopify_path, error: 'Could not Authenticate'
    end

    access_token = @shopify_session.request_token(params)
    if access_token.present?
      @shopify_credential.update(access_token: access_token, kind: 'hingeto_app')
    end

    redirect_to retailer_integrations_shopify_path
  end

  private

  def shopify_credential_params
    params.require(:shopify_credential).permit(
      :api_key, :password, :shared_secret, :retailer_id, :store_url
    )
  end

  def set_shopify_session
    ShopifyAPI::Session.secret = ENV['SHOPIFY_APP_SECRET_KEY']
    ShopifyAPI::Session.api_key = ENV['SHOPIFY_API_KEY']
    @team = current_spree_user.team_member.teamable

    @shopify_credential = Spree::ShopifyCredential.find_or_initialize_by(retailer_id: @team.id)

    return unless @shopify_credential.present? && @shopify_credential.store_url.present?

    @shopify_session = ShopifyAPI::Session.new(
      domain: @shopify_credential.store_url,
      token: @shopify_credential.access_token,
      api_version: ENV['SHOPIFY_API_VERSION']
    )
  end
end
