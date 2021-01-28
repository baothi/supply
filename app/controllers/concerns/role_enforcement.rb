module RoleEnforcement
  extend ActiveSupport::Concern

  included do
    # before_action :ensure_current_user_is_retailer_owner
  end

  private

  def currently_in_impersonation_mode?
    true_spree_user.present?
  end

  def ensure_current_user_is_retailer_owner
    return if current_spree_user.team_member&.role&.name == Spree::Retailer::RETAILER_OWNER ||
              admin_user?

    redirect_to retailer_settings_advanced_index_path, alert: "You're not the store owner"
  end

  def ensure_retailer_owner_role
    return if current_spree_user.team_member&.role&.name == Spree::Retailer::RETAILER_OWNER ||
              admin_user?

    redirect_to retailer_settings_advanced_index_path, alert: "You're not the store owner"
  end

  def ensure_current_user_is_supplier_owner
    return if current_spree_user.team_member&.role&.name == Spree::Retailer::SUPPLIER_OWNER ||
              admin_user?

    redirect_to supplier_dashboard_path, alert: "You're not the owner"
  end

  def ensure_supplier_owner_role
    return if current_spree_user.team_member&.role&.name == Spree::Retailer::SUPPLIER_OWNER ||
              admin_user?

    redirect_to supplier_dashboard_path, alert: "You're not the owner"
  end
end
