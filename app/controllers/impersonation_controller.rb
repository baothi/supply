class ImpersonationController < ApplicationController
  def impersonate
    team_member = Spree::TeamMember.find_by_internal_identifier(params[:impersonation_id])
    imposter = team_member.user

    real_user = warden.user(:user)

    if real_user == imposter
      redirect_to(root_path, alert: 'You are already impersonating this user.') && return
    end

    save_real_user_for_later_for_warden(real_user)
    impersonate_user_from_warden_perspective(imposter)

    first_name = current_spree_user.first_name
    team_name = team_member.teamable.name

    impersonate_spree_user(imposter)

    redirect_to(
      dashboard_path_for_role(current_spree_user.team_member.teamable),
      flash: { notice: "You are now impersonating #{first_name} from #{team_name}" }
    )
  end

  def stop_impersonating
    # Pretender
    stop_impersonating_spree_user

    # Warden
    stop_impersonating_user_from_warden_perspective
    restore_real_user_from_wardens_perspective

    redirect_to dashboard_path_for_role(current_spree_user.team_member.teamable),
                flash: { notice: 'Impersonation stopped!' }
  end

  private

  def set_team; end

  # Warden Helpers

  def impersonate_user_from_warden_perspective(imposter)
    cookies.signed[:impersonated_user_id] = imposter.id
    cookies.signed[:impersonated_user_expires_at] = 1.day.from_now
    warden.set_user(imposter, scope: :user)
  end

  def restore_real_user_from_wardens_perspective
    real_user_id = cookies.delete(:real_user_id)

    return unless real_user_id.present?

    real_user = Spree::User.find(real_user_id)
    warden.set_user(real_user, scope: :user)
  end

  def save_real_user_for_later_for_warden(user)
    return unless user.present? && user.is_a?(Spree::User)

    cookies.signed[:real_user_id] = user.id if cookies.signed[:impersonated_user_id].nil?
    warden.logout(:user)
  end

  def stop_impersonating_user_from_warden_perspective
    cookies.delete(:impersonated_user_id)
    cookies.delete(:impersonated_user_expires_at)
    imposter = warden.user(:user)
    warden.logout(:user)
    imposter
  end
end
