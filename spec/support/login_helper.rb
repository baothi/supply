def retailer_admin_login
  @retailer = spree_retailer
  @team_member = @retailer.team_members.first
  @current_user = @team_member.user

  @admin_role = create :spree_role, name: Spree::Retailer::RETAILER_ADMIN
  @current_user.update(role: @admin_role)
  login_as(@current_user, scope: :spree_user)
end
