class ProfilesController < BaseController
  def index
    @profile = Struct.new(:email, :password, :name)
  end

  def switch_team
    team_member = Spree::TeamMember.find_by(internal_identifier: params[:internal_identifier])

    if team_member.present?
      current_spree_user.update(default_team_member_id: team_member.id)
      flash[:notice] = "Switched to #{team_member.teamable.name}"
    else
      flash[:alert] = 'Team not found'
    end

    redirect_to dashboard_path_for_role(team_member.teamable)
  end
end
