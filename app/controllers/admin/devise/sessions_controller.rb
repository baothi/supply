class Admin::Devise::SessionsController < BaseController
  skip_before_action :authenticate_spree_user!

  layout 'logout'

  helper_method :resource_name, :resource, :devise_mapping, :resource_class

  def resource_name
    :admin_user
  end

  def resource
    @resource ||= AdminUser.new
  end

  def resource_class
    AdminUser
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:admin_user]
  end
end
