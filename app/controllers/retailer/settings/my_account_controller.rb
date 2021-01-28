class Retailer::Settings::MyAccountController < Retailer::BaseController
  skip_before_action :confirm_paying_customer?
  skip_before_action :confirm_onboarded?

  def index; end

  def update_account
    puts 'Params: '.yellow
    puts user_params.inspect

    puts "Comparing: #{current_spree_user.email.downcase} with #{user_params[:email].downcase}"
    updated_user_params = if !current_spree_user.email.casecmp(user_params[:email]).zero?
                            user_params.merge(confirmed_at: nil, confirmation_sent_at: nil)
                          else
                            user_params
                          end

    if current_spree_user.update(updated_user_params)
      flash[:notice] = 'Settings Updated'
      redirect_to action: :index and return
    end

    flash.now[:alert] = 'There was an error saving the settings'
    render :index
  end

  def update_retailer_account
    if current_retailer.update(retailer_params)
      flash[:notice] = 'Settings Updated'
      redirect_to action: :index and return
    end

    flash.now[:alert] = 'There was an error saving the settings'
    render :index
  end

  def update_password
    if current_spree_user.update_with_password(user_params.merge(using_temporary_password: false))
      sign_in(current_spree_user, bypass: true)
      return redirect_to account_retailer_settings_path, notice: 'Password Changed Successfully'
    end

    render :index
  end

  private

  def retailer_params
    params.require(:retailer).permit(:name)
  end

  def user_params
    params.require(:user).permit(:email,
                                 :password, :first_name, :last_name, :password_confirmation,
                                 :current_password)
  end

  # def retailer_auto_payment_setting
  #   if current_retailer.update(order_auto_payment: params[:auto_pay])
  #     flash[:notice] = 'Auto paymemnt setting updated!'
  #   else
  #     flash[:alert] = 'Error update auto payment settings'
  #   end
  #
  #   redirect_to action: :index
  # end
end
