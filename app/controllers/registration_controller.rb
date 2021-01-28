class RegistrationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :ensure_accepted_terms, only: :create_supplier
  before_action :verify_signup_key, only: :supplier

  layout 'registration'

  def supplier
    redirect_to root_path, alert: 'Please contact Hingeto for Signup link'
    # @supplier = Users::Registration::Supplier.new
  end

  def create_supplier
    # @supplier = Users::Registration::Supplier.new(supplier_params)
    # if @supplier.execute
    #   sign_in @supplier.user
    #   return redirect_to supplier_dashboard_path, notice: 'Welcome to Hingeto Supply'
    # end
    #
    # flash.now[:alert] = "Errors!! <br> – #{@supplier.errors}".html_safe
    # render :supplier
  end

  private

  def supplier_params
    params.require(:supplier).permit(
      :business_name, :first_name, :last_name, :email, :password, :password_confirmation
    )
  end

  def ensure_accepted_terms
    return if params[:term] == 'on'

    flash.now[:alert] = 'Please check the terms box'
    @supplier = Users::Registration::Supplier.new(supplier_params)
    render :supplier
  end

  def verify_signup_key
    return if params[:ref] == ENV['SUPPLIER_SIGNUP_REF']

    redirect_to root_path, alert: 'Please contact Hingeto for Signup link'
  end
end
