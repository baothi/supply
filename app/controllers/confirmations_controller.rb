class ConfirmationsController < Devise::ConfirmationsController
  skip_before_action :enforce_limited_access
  skip_before_action :authenticate_spree_user!

  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)

    if successfully_sent?(resource)
      flash[:notice] = 'Please check your email.'
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  # private

  def after_confirmation_path_for(_resource_name, resource)
    # sign_in(resource) # In case you want to sign in the user
    default_initial_path_for_role(resource)
  end
end
