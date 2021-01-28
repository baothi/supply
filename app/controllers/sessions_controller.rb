class SessionsController < Devise::SessionsController
  skip_before_action :enforce_limited_access
  layout 'registration'
end
