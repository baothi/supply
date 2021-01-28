class Retailer::HelpController < Retailer::BaseController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :confirm_onboarded?

  layout 'registration'

  def overview; end

  def download_guide
    r = current_retailer
    r.setting_downloaded_guide = true
    r.save!

    redirect_to ENV['GUIDE_RETAILER_URL']
    nil
  end
end
