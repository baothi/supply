class Retailer::ShopifySelectPlanController < ApplicationController
  # skip_before_action :confirm_access_granted! Not needed since doesn't inherit Retailer Controller

  protect_from_forgery with: :exception

  layout 'registration'

  # include Wicked::Wizard

  def index
    # Right now there is only one plan using the billing api so
    # we can just redirect directly to the install path
    if ENV['USE_SHOPIFY_BILLING']
      redirect_to retailer_install_shopify_app_path
    else
      redirect_to retailer_select_plan_path
    end
  end
end
