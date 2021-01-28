class PricingPlanController < ApplicationController
  skip_before_action :authenticate_spree_user!
  skip_before_action :enforce_limited_access

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # layout 'root'

  layout 'registration'

  # include Wicked::Wizard
  def initiate_session; end

  def index
    # plan_FzMm2BAPBCSPdZ
    Stripe.api_key = ENV['STRIPE_API_KEY']

    options = {
        payment_method_types: ['card'],
        subscription_data: {
            items: [{
                        plan: params[:plan_id]
                    }],
            trial_period_days: 14,
            metadata: {
                role: params[:role]
            }
        },
        success_url: "#{ENV['SITE_URL']}/pricing_plan/#{params[:role]}/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: 'https://www.hingeto.com/pricing'
    }

    if current_spree_user.present? && current_spree_user.team_member.present?
      options[:client_reference_id] = "#{@team_type}-#{@team.id}"
      # options[:customer] = @team.current_stripe_customer_identifier
      options[:customer_email] = @team.current_stripe_customer_email || @team.email || spree_current_user.email
    end

    @session = Stripe::Checkout::Session.create(options)
  end

  def valid_role_param?(role)
    return true if role == 'supplier' || role == 'retailer'

    false
  end

  def success
    # Create account
    session_id = params[:session_id]
    role = params[:role]
    if role.blank? || !valid_role_param?(role)
      flash[:alert] = 'You cannot access this page!'
      redirect_to root_path
      return
    end

    if session_id.blank?
      flash[:alert] = 'You cannot access this page!'
      redirect_to root_path
      return
    end

    # flash[:notice] = 'Thanks for your payment! Please check your email for the next steps.'
    Stripe.api_key = ENV['STRIPE_API_KEY']
    checkout_session = Stripe::Checkout::Session.retrieve(session_id)
    customer_identifier = checkout_session.customer
    subscription_identifier = checkout_session.subscription
    customer = Stripe::Customer.retrieve(customer_identifier)
    subscription = Stripe::Subscription.retrieve(subscription_identifier)
    plan_identifier = subscription.plan.id
    # Create Teamable
    results = create_teamable(
      role: params[:role].downcase,
      email: customer.email,
      customer: customer,
      subscription_identifier: subscription_identifier,
      plan_identifier: plan_identifier
    )
    # Results
    teamable_user = results[0]
    # teamable = results[1]

    # Fix Issues
    if current_spree_user.present?
      # Just In case they are't somehow logged in to the current account
      sign_out(current_spree_user) unless current_spree_user.nil?
      sign_in(teamable_user)
    else
      sign_in(teamable_user)
    end

    redirect_to determine_onboarding_path(role)
    nil
  end

  def determine_onboarding_path(role)
    case role
    when 'supplier'
      supplier_onboarding_path
    when 'retailer'
      retailer_onboarding_path
    else
      raise 'Unknown role for onboarding'
    end
  end

  def create_teamable(role:, email:,
                      customer:,
                      subscription_identifier:, plan_identifier:)
    # Create Teamable - Supplier or Retailer
    teamable = "Spree::#{role.camelize}".constantize.new
    teamable.name = "Retailer for #{email} - #{DateTime.now.to_i}"
    teamable.email = email
    teamable.access_granted_at = DateTime.now
    teamable.completed_onboarding_at = nil
    teamable.current_stripe_subscription_identifier = subscription_identifier
    teamable.current_stripe_subscription_started_at = DateTime.now
    teamable.current_stripe_plan_identifier = plan_identifier
    teamable.current_stripe_customer_identifier = customer.id
    teamable.current_stripe_customer_email = customer.email
    teamable.save!

    # Save Stripe Information using legacy means for now
    StripeService.save_customer_to_db(
      StripeCustomer.new(strippable: teamable), customer
    )

    # StripeService.add_card_to_customer(customer, card_token)

    # Create User
    # TODO: Ensure that this can create a secondary email address if it's already taken
    # otherwise once assigned to multiple teams, we won't know where to log them into
    # unless we change our login flow

    temp_pass = SecureRandom.hex(6)
    teamable_user = Spree::User.where(email: email).first_or_create! do |user|
      user.first_name = 'N/A'
      user.last_name = 'N/A'
      user.password = temp_pass
      user.using_temporary_password = true
    end

    # Generate Token
    if teamable_user.confirmation_token.nil?
      teamable_user.regenerate_confirmation_token!
    end

    UserMailer.welcome_new_user(teamable, teamable_user, temp_pass, teamable.id).deliver_later

    # Create Role
    owner_role = Spree::Role.find_or_create_by(
      name: "Spree::#{role.camelize}::#{role.upcase}_OWNER".constantize
    )

    # Add User to Team
    teamable.team_members.first_or_create do |team|
      team.user_id = teamable_user.id
      team.role_id = owner_role.id
    end

    [teamable_user, teamable]
  end

  def cancel
    # redirect_to
  end

  private
end
