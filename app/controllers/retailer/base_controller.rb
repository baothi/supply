class Retailer::BaseController < ApplicationController
  include DynamicRoutable

  before_action :authenticate_retailer!
  # before_action :confirm_access_granted?
  before_action :confirm_paying_customer?
  before_action :confirm_onboarded?

  helper_method :current_retailer
  helper_method :live_shopify_products_identifiers

  layout 'platform'

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

  def confirm_paying_customer?
    unless @retailer.has_subscription?
      # flash[:alert] = 'Please select a plan'
      redirect_to get_retailer_select_plan_path
      nil
    end
  end

  def confirm_onboarded?
    unless @retailer.onboarded?
      # flash[:alert] = 'Please select a plan'
      redirect_to retailer_onboarding_path
      nil
    end
  end

  def confirm_access_granted?
    unless @retailer.access_granted?
      # flash[:alert] = 'Please select a plan'
      redirect_to get_retailer_select_plan_path
      nil
    end
  end

  # TODO: This is flawed. We need to rewrite
  def current_retailer
    # @retailer ||= Spree::TeamMember.find_by(user_id: current_spree_user.id).teamable
    @retailer
  end

  def live_shopify_products_identifiers
    return [] if @retailer.nil?

    Spree::Product.unscoped.listed_for_retailer(current_retailer).pluck(:internal_identifier)
  end
end
