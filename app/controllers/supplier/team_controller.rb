class Supplier::TeamController < Supplier::BaseController
  include RoleEnforcement

  before_action :ensure_supplier_admin_role, only: %i(add_account update_account)
  before_action :ensure_user_not_exist, only: :add_account
  before_action :ensure_current_user_is_supplier_owner, only: :delete_account
  before_action :find_team_member_from_current_team, only: %i(member update_account delete_account)

  def index; end

  def member; end

  def add_account
    if current_supplier.add_team_member(
      user_params.merge(shopify_url: current_spree_user.shopify_url),
      params[:spree_role_id]
    )
      return redirect_to supplier_team_index_path, notice: 'User added successfully'
    end

    redirect_to supplier_team_index_path, alert: 'Error creating new account'
  end

  def delete_account
    if @team_member && @team_member&.role&.name == Spree::Supplier::SUPPLIER_OWNER
      flash[:alert] = 'Supplier Owner account cannot be removed.'
      redirect_to supplier_team_index_path and return
    end

    user = @team_member.user
    full_name = user.full_name
    success = false

    ActiveRecord::Base.transaction do
      user.destroy!
      @team_member.destroy!
      success = true
    end

    if success
      flash[:notice] = "#{full_name} was successfully removed."
      redirect_to supplier_team_index_path and return
    end

    flash.now[:alert] = 'Error deleting team member'
    render :member
  end

  def update_account
    if @team_member.update(team_member_params)
      flash[:notice] = "#{@team_member.user.full_name}'s role updated successfully"
      redirect_to supplier_team_index_path and return
    end

    flash.now[:alert] = 'Error updating team member role'
    render :member
  end

  private

  def ensure_supplier_admin_role
    role_id = params[:spree_role_id] || team_member_params[:role_id]
    role = Spree::Role.find_by(id: role_id)
    puts role.inspect
    return if role && (role.name == Spree::Supplier::SUPPLIER_ADMIN)

    flash[:alert] = 'Invalid role id supplied'
    redirect_back fallback_location: supplier_team_index_path
  end

  def ensure_user_not_exist
    shop = current_spree_user.shopify_url
    return unless Spree::User.find_by(email: user_params[:email], shopify_url: shop)

    redirect_to supplier_team_index_path, alert: 'Email already in use within team'
  end

  def find_team_member_from_current_team
    identifier = params[:internal_identifier] || team_member_params[:internal_identifier]
    @team_member = current_supplier.team_members.find_by(internal_identifier: identifier)
    return if @team_member

    redirect_to supplier_team_index_path, alert: 'Team member not found'
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :first_name, :last_name, :password_confirmation, :current_password
    )
  end

  def team_member_params
    params.require(:team_member).permit(:internal_identifier, :role_id)
  end
end
