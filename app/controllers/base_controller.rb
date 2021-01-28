class BaseController < ApplicationController
  include SharedMethods

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  layout 'platform'

  def sidebar
    render 'shared/_site-sidebar', layout: false
  end
end
