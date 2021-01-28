class SupplierOnboardingController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout 'registration'

  def basic_information; end

  def payment_information; end

  def contact_information; end

  def customer_service; end

  def seller_agreement; end

  def completed; end
end
