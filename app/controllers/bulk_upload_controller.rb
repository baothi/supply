class BulkUploadController < BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'platform'

  def index; end

  def product; end

  def order; end

  def sidebar
    render 'shared/_site-sidebar', layout: false
  end
end
