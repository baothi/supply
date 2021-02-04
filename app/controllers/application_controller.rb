class ApplicationController < ActionController::Base
  include SharedMethods
  include DynamicRoutable
  # include Adminable

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_is_modern_browser
  before_action :authenticate_spree_user!, if: :not_active_admin_route_or_is_review_app?
  before_action :admin_user_from_regular_user!, if: :review_app?
  before_action :set_timezone
  before_action :set_team, unless: :active_admin_route?

  before_action :enforce_limited_access, if: :in_limbo_team?
  # before_action :enforce_limited_access, if: :demo_user?

  attr_reader :retailer
  helper_method :retailer
  helper_method :admin_user?

  impersonates :spree_user,
               method: :current_spree_user,
               with: ->(id) { Spree::User.find_by(id: id) }

  def check_is_modern_browser
    return if Rails.env.test?
    use Browser::Middleware do

      redirect_to browser_not_supported_path unless browser.modern_browser?
    end
  end

  def after_sign_in_path_for(_resource)
    team_member = current_spree_user.team_member
    # @retailer = set_retailer if @retailer.nil?

    return determine_post_login_path(team_member, nil) if team_member

    invalid_team_association_detected
  end

  def post_login_path(teamable)
    if teamable.has_subscription? && teamble.completed_onboarding?
      return supplier_dashboard_path if team_member.teamable.is_a?(Spree::Supplier)
      return retailer_dashboard_path if team_member.teamable.is_a?(Spree::Retailer)
    elsif teamable.has_subscription? && !teamable.completed_onboarding?
      return supplier_onboarding_path if teamable.is_a?(Spree::Supplier)
      return retailer_onboarding_path if teamable.is_a?(Spree::Retailer)
    else
      return get_select_plan_path(team_member)
    end
  end

  def determine_post_login_path(team_member, _retailer)
    # We only want suppliers connected to the current retailer
    # teamable = team_member.teamable
    # if team_member.teamable.is_a?(Spree::Supplier) &&
    #    retailer.connected_to_supplier?(teamable)
    #   @supplier = team_member.teamable
    #   return supplier_dashboard_path
    #   # We only want members of the retailer whose domain we are on, to be able to login
    # elsif team_member.teamable.is_a?(Spree::Retailer) &&
    #       team_member.also_member_of_retailer?(retailer)
    #   return retailer_dashboard_path
    # end

    # teamable = team_member.teamable

    if paying_team? && onboarded_team?
      return supplier_dashboard_path if team_member.teamable.is_a?(Spree::Supplier)
      return retailer_dashboard_path if team_member.teamable.is_a?(Spree::Retailer)
    elsif paying_team? && !onboarded_team?
      return supplier_onboarding_path if team_member.teamable.is_a?(Spree::Supplier)
      return retailer_onboarding_path if team_member.teamable.is_a?(Spree::Retailer)
    else
      return get_select_plan_path(team_member)
    end

    invalid_team_association_detected
  end

  def invalid_team_association_detected
    sign_out current_spree_user
    flash[:alert] = 'No team associated with your account'
    new_spree_user_session_path
  end

  def dashboard_path_for_role(teamable)
    case teamable.class.name
    when 'Spree::Retailer'
      retailer_dashboard_path
    when 'Spree::Supplier'
      supplier_dashboard_path
    else
      root_path
    end
  end

  def set_timezone
    Time.zone = 'Pacific Time (US & Canada)' # current_spree_user.timezone
  end

  # This also sets retailer object

  def set_team
    return if current_spree_user.nil?
    return if current_spree_user.team_member.nil?

    @team = current_spree_user.team_member.teamable
    @team_member = current_spree_user.team_member
    @team_type = params[:team_type] || team_member_type_from_session

    @retailer = @team if @team_type == 'Spree::Retailer'
    @supplier = @team if @team_type == 'Spree::Supplier'
  end

  def team_member_type_from_session
    current_team_type = current_spree_user.team_member.teamable_type
    current_team_type.split('Spree::')[1].downcase
  end

  def enforce_retailer
    enforce_role('retailer')
  end

  def enforce_supplier
    enforce_role('supplier')
  end

  def enforce_role(role_name = nil)
    return if role_name.blank?

    raise 'You cannot access this resource' if
        team_member_type_from_session != role_name
  end

  def admin_user?
    (true_spree_user.present? && true_spree_user.hingeto_user?) ||
      (current_spree_user.present? && current_spree_user.hingeto_user?) ||
      admin_user_signed_in?
  end

  def restrict_page_to_hingeto_user
    return if admin_user?

    redirect_back fallback_location: dashboard_path_for_role(current_spree_user.teamable),
                  alert: 'Access denied for requested page'
  end

  def active_admin_route?
    controller_path.include?('admin')
  end

  def review_app?
    Supply::ReviewApp::Helpers.review_app?
  end

  def not_active_admin_route_or_is_review_app?
    !active_admin_route? || review_app?
  end

  def admin_user_from_regular_user!
    return unless review_app?
    return unless spree_user_signed_in?

    user = true_spree_user || current_spree_user
    return unless user.hingeto_user?

    admin_user = AdminUser.find_or_create_by(email: user.email) do |u|
      u.provider = 'fake-google-oauth'
      u.uid = SecureRandom.hex
      u.name = user.full_name
    end

    sign_in admin_user
  end

  def in_limbo_team?
    current_spree_user&.team_member&.teamable&.access_granted?
  end

  def onboarded_team?
    current_spree_user&.team_member&.teamable&.onboarded?
  end

  def paying_team?
    current_spree_user&.team_member&.teamable&.has_subscription?
  end

  def enforce_limited_access
    return if admin_user?

    # redirect_back fallback_location: referrals_path_for_role(current_spree_user.teamable),
    #               alert: 'Access denied for requested page'
  end

  # def referrals_path_for_role(teamable)
  #   case teamable.class.name
  #   when 'Spree::Retailer'
  #     retailer_referrals_path
  #   when 'Spree::Supplier'
  #     supplier_referrals_path
  #   else
  #     root_path
  #   end
  # end

  def default_initial_path_for_role(teamable)
    case teamable.class.name
    when 'Spree::Retailer'
      get_retailer_select_plan_path
    when 'Spree::Supplier'
      get_supplier_select_plan_path
    else
      root_path
    end
  end

  def referrals_path_for_role(teamable)
    case teamable.class.name
    when 'Spree::Retailer'
      get_retailer_select_plan_path
    when 'Spree::Supplier'
      get_supplier_select_plan_path
    else
      root_path
    end
  end
end
