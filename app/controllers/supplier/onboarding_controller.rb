class Supplier::OnboardingController < Supplier::BaseController
  skip_before_action :confirm_onboarded?

  protect_from_forgery with: :exception

  layout 'registration'

  # include Wicked::Wizard

  def index
    @supplier = current_supplier
  end
end
