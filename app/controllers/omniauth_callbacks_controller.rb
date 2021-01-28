class  OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def all
    user = AdminUser.from_omniauth request.env['omniauth.auth']
    if user.persisted?
      flash.notice = 'Signed in!'
      sign_in user
      redirect_to admin_dashboard_path
    else
      flash.notice = "We couldn't sign you in because: " + user.errors.full_messages.to_sentence
      redirect_to new_admin_user_session_url
    end
  end

  alias_method :google_oauth2, :all
end
