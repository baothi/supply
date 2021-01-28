class Retailer::ShopifyRecurringChargeController < ApplicationController
  before_action :authenticate_retailer!

  include ShopifyAuth
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_retailer

  def create
    current_retailer.init

    # Cancel any current recurring application charge
    @recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.current

    # This will need to be changed if we add tiers but since we only have one possible monthly rate
    # this should work for now
    if @recurring_application_charge.try!(:status) == 'active'
      redirect_to root_url 
      return
    end

    @recurring_application_charge.try!(:cancel)
    credential = current_retailer.shopify_credential
    trial_days = current_retailer.remaining_trial_time/60/60/24 # Seconds to days
    params = {
      name: 'TeamUp App',
      price: 99.00, # Hardcoded for now if we add plans this will be variable
      trial_days: trial_days,
      return_url: retailer_recurring_charge_callback_url,
      test: ENV['SHOPIFY_BILLING_TEST']
    }

    @recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.new(params)

    if @recurring_application_charge.save
      redirect_to @recurring_application_charge.confirmation_url
    else
      flash[:error] = @recurring_application_charge.errors.full_messages.first.to_s.capitalize
      charge_failed
      redirect_to root_path
    end
  end

  def callback
    # verify_shopify_request

    current_retailer.init
    @recurring_application_charge = ShopifyAPI::RecurringApplicationCharge.find(params[:charge_id])
    if @recurring_application_charge.status == 'accepted'
      @recurring_application_charge.activate
      current_retailer.current_shopify_subscription_identifier = @recurring_application_charge.id
      current_retailer.trial_started_on = Time.now
      current_retailer.save!
    else
      flash[:error] = 'You must accept the recurring charge to use this application.'
      charge_failed
    end
    redirect_to root_path
  end

  private

  def charge_failed
    # If we fail to make the charge we want to disable the shopify credential
    # so that the user does not have access without paying
    shopify_credential = current_retailer.shopify_credential
    shopify_credential.destroy
  end

  def authenticate_retailer!
    @team_member ||= current_spree_user.team_member
    if @team_member.nil?
      sign_out
      redirect_to root_url
      return
    end
    teamable = @team_member.teamable
    @retailer = teamable
    return if teamable.class.name == 'Spree::Retailer'

    flash[:alert] = 'You do not belong to a retailer team'
    redirect_to dashboard_path_for_role(teamable)
  end

  def current_retailer
    @retailer
  end
end