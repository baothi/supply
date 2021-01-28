module DynamicRoutable
  extend ActiveSupport::Concern

  private

  def get_select_plan_path(team_member)
    path = get_supplier_select_plan_path if team_member.teamable.is_a?(Spree::Supplier)
    path = get_retailer_select_plan_path if team_member.teamable.is_a?(Spree::Retailer)
    path
  end

  def get_supplier_select_plan_path
    supplier_select_plan_path
  end

  def get_retailer_select_plan_path
    return retailer_select_plan_path unless ENV['USE_SHOPIFY_BILLING']
    return retailer_select_shopify_plan_path
  end
end
