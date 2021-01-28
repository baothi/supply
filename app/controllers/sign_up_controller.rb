class SignUpController < ActionController::Base
  protect_from_forgery with: :exception

  layout 'registration'

  include Wicked::Wizard

  steps :retailer, :supplier

  def show
    case step
    when :retailer
      @user = Users::SignUp::User.new(type: params[:type], user_id: session[:user_id])
    when :supplier
      @user = Users::SignUp::User.new(type: params[:type], user_id: session[:user_id])
    else
      redirect_to new_sign_up_path, alert: 'Oops! Something went wrong.'
    end

    render_wizard
  end

  def new
    @user = Users::SignUp::User.new
  end

  def create
    @user = Users::SignUp::User.new(user_params)
    if @user.save_user
      session[:user_id] = @user.user.id
      if user_params[:type] == 'retailer' || user_params[:type].nil?
        redirect_to wizard_path(steps.first, type: 'retailer')
      elsif user_params[:type] == 'supplier'
        redirect_to wizard_path(steps.last, type: 'supplier')
      else
        render :new
      end
    else
      flash.now[:alert] = "Errors: #{@user.errors}".html_safe
      render :new
    end
  end

  def update
    case step
    when :retailer
      @user = Users::SignUp::User.new(retailer_params)
      if @user.save
        sign_in @user.user
        redirect_to_finish_wizard retailer_add_referral_path
      else
        flash.now[:alert] = "Errors: #{@user.errors}".html_safe
        render template: 'sign_up/retailer'
      end
      #
      # redirect_to next_wizard_path
    when :supplier
      @user = Users::SignUp::User.new(supplier_params)
      if @user.save
        sign_in @user.user
        redirect_to_finish_wizard supplier_add_referral_path
      else
        flash.now[:alert] = "Errors: #{@user.errors}".html_safe
        render template: 'sign_up/supplier'
      end
    else
      redirect_to new_sign_up_path, alert: 'Oops! Something went wrong.'
    end
  end

  private

  def redirect_to_finish_wizard(path)
    redirect_to path, notice: 'Thank you! for signing up.'
  end

  def user_params
    params.require(:users_sign_up_user).permit(
      :email, :password, :password_confirmation, :type
    )
  end

  def supplier_params
    supplier_or_retailer_params.merge(type: 'supplier', user_id: session[:user_id])
  end

  def retailer_params
    supplier_or_retailer_params.merge(type: 'retailer', user_id: session[:user_id])
  end

  def supplier_or_retailer_params
    params.require(:users_sign_up_user).permit(
      :business_name,
      :website,
      :facebook_url,
      :instagram_url,
      :ecommerce_platform,
      :phone_number
    )
  end
end
