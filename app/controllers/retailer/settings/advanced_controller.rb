class Retailer::Settings::AdvancedController < Retailer::BaseController
  include RoleEnforcement

  before_action :ensure_retailer_owner_role, only: :transfer_ownership

  def index; end

  def transfer_ownership
    # new_owner_member = current_retailer.team_members.find_by(id: params[:new_owner])
    #
    # current_team_member = current_spree_user.team_member
    # if current_team_member.transfer_ownership_to(new_owner_member)
    #   return redirect_to retailer_settings_advanced_index_path, notice: 'Ownership tranfered'
    # end
    #
    # redirect_to retailer_settings_advanced_index_path,
    #             alert: current_team_member.errors.full_messages.join('. ')
  end
end
