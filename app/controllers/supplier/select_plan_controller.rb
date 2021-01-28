class Supplier::SelectPlanController < ApplicationController
  # skip_before_action :confirm_access_granted! Not needed since doesn't inherit Retailer Controller

  protect_from_forgery with: :exception

  layout 'registration'

  # include Wicked::Wizard

  def index; end
end
