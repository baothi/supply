class Retailer::PaymentsController < Retailer::BaseController
  include EnsureStrippable
  before_action :ensure_have_credit_card, :set_plan, only: %i(update_plan_subscription)

  def save_billing_card
    if StripeService.add_card_to_customer(current_retailer.stripe_customer, params[:token])
      flash[:notice] = 'Credit card successfully added.'
      redirect_to retailer_settings_billing_information_path and return
    end

    flash[:alert] = 'Error adding card to user'
    redirect_to retailer_settings_billing_information_path
  end

  def index
    @payment_cards = current_retailer.stripe_cards
  end

  def mark_card_as_default
    card = StripeCard.find_by(internal_identifier: params[:id])
    if card && StripeService.set_default_card(current_retailer.stripe_customer, card)
      flash[:notice] = 'Card marked as default.'
      redirect_to retailer_payments_path and return
    end

    flash[:alert] = 'Error marking selected card as default. Please try again.'
    redirect_to retailer_payments_path
  end

  def remove_billing_card
    card = StripeCard.find_by(internal_identifier: params[:id])
    if card && StripeService.delete_card(current_retailer.stripe_customer, card)
      flash[:notice] = 'Card deleted successfully.'
      # redirect_to retailer_settings_billing_information_path and return
      redirect_to retailer_payments_path and return
    end

    flash[:alert] = 'Unable to delete selected card. Please try again.'
    redirect_to retailer_settings_billing_information_path
  end

  def update_plan_subscription
    if StripeService.create_or_update_subscription(current_retailer.stripe_customer, @plan)
      flash[:notice] = 'Your subscription plan has been set successfully.'
      redirect_to retailer_payments_path and return
    end

    redirect_to retailer_payments_path,
                alert: 'An error occurred processing your plan. Please try again.'
  end

  def new_card
    if StripeService.add_card_to_customer(current_retailer.stripe_customer, params[:token])
      flash.now[:notice] = 'Successfully added new credit card!'
      @success = true
      @payment_cards = current_retailer.stripe_cards
    else
      flash.now[:error] = 'Could not add new card. Please try again.'
      @success = false
    end

    @payment_cards = current_retailer.stripe_cards
    # redirect_to retailer_payments_path
    respond_to do |format|
      format.js { render 'new_card' }
    end
  end

  private

  def ensure_have_credit_card
    return if current_retailer.stripe_customer.try(:stripe_cards).present?

    flash[:alert] = 'Please enter your billing information before choosing a plan. Or set default'
    redirect_to retailer_settings_billing_information_path
  end

  def set_plan
    @plan = StripePlan.find_by(plan_identifier: params[:plan_identifier])
    return if @plan

    redirect_to retailer_payments_path, alert: 'Invalid plan identifier. Please select a plan'
  end
end
