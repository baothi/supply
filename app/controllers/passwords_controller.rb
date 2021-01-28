class PasswordsController < Devise::PasswordsController
  skip_before_action :enforce_limited_access
  layout 'registration'

  def create
    self.resource = resource_class.send_reset_password_instructions(
      resource_params
    )

    if successfully_sent?(resource)
      flash[:notice] = 'Please check your email.'
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end
end
