class Retailer::OnboardingController < Retailer::BaseController
  skip_before_action :confirm_onboarded?

  protect_from_forgery with: :exception

  layout 'registration'

  # include Wicked::Wizard

  def index
    @retailer = current_retailer
  end

  def begin_selling
    # Only allow them to begin selling, if we are not using specialists for onboarding.
    if ENV['ONBOARDING_FLOW'] == 'with_specialist'
      redirect_back fallback_location: retailer_onboarding_path,
                    notice: 'You cannot self onboard.'
      nil
    end

    if ENV['ONBOARDING_FLOW'] == 'without_specialist'
      can_self_onboard =
        current_retailer.completed_onboarding_prep_for_flow_without_specialist?(current_spree_user)

      unless can_self_onboard
        redirect_back fallback_location: retailer_onboarding_path,
                      notice: 'You cannot self onboard. Please complete all the steps'
        nil
      end

    end

    @retailer = current_retailer
    # Assign Selling Authority
    @retailer.grant_access_to_marketplace_suppliers!
    @retailer.complete_onboarding!

    redirect_to retailer_dashboard_path, notice: 'Welcome to TeamUp'
  end
end
