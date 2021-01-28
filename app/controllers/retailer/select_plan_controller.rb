class Retailer::SelectPlanController < ApplicationController
  # skip_before_action :confirm_access_granted! Not needed since doesn't inherit Retailer Controller

  protect_from_forgery with: :exception

  layout 'registration'

  # include Wicked::Wizard

  def index
    if ENV['USE_SHOPIFY_BILLING']
      redirect_to retailer_shopify_select_plan_path
    end
  end
end
