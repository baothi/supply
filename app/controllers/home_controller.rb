class HomeController < ApplicationController
  skip_before_action :authenticate_spree_user!
  skip_before_action :enforce_limited_access

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'root'

  def index
    redirect_to '/login'
  end

  def mark_appointment_as_scheduled
    return if spree_current_user.nil? || @team.nil?
    return unless @team_type == 'retailer' # TODO: Change

    @team.scheduled_onboarding_at = DateTime.now
    @team.save!
    head :ok
  end

  def send_confirmation_instructions_notification
    if spree_current_user.nil?
      redirect_to :back,
                  notice: 'Your email confirmation instructions has been resent',
                  fallback: root_path
      return
    end

    if spree_current_user.confirmation_token.nil?
      spree_current_user.regenerate_confirmation_token!
    end
    token = spree_current_user.confirmation_token
    ::UserMailer.confirmation_instructions(spree_current_user, token, {}).deliver_later
    redirect_to :back,
                notice: 'Your email confirmation instructions has been resent',
                fallback: root_path
  end

  def browser_not_supported; end
end
