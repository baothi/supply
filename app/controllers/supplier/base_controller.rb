class Supplier::BaseController < ApplicationController
  include DynamicRoutable

  before_action :authenticate_supplier!
  before_action :set_team

  before_action :confirm_paying_customer?
  before_action :confirm_onboarded?

  helper_method :current_supplier

  layout 'platform'

  def authenticate_supplier!
    @supplier = current_spree_user.team_member.teamable
    return if @supplier.class.name == 'Spree::Supplier'

    flash[:alert] = 'You do not belong to a supplier team'
    redirect_to dashboard_path_for_role(@supplier)
  end

  def confirm_paying_customer?
    unless @supplier.has_subscription?
      # flash[:alert] = 'Please select a plan'
      redirect_to get_supplier_select_plan_path
      nil
    end
  end

  def confirm_onboarded?
    if @supplier.onboarded?
      # flash[:alert] = 'Please select a plan'
      redirect_to supplier_onboarding_path
      nil
    end
  end

  def confirm_access_granted?
    unless @supplier.access_granted?
      # flash[:alert] = 'Please select a plan'
      redirect_to get_supplier_select_plan_path
      nil
    end
  end

  def current_supplier
    @supplier
  end
end
