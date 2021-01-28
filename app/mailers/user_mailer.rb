class UserMailer < ApplicationMailer
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default from: "TeamUp <#{ENV['NOREPLY_EMAIL']}>"

  helper :application # gives access to all helpers defined within `application_helper`.

  def reset_password_instructions(user, token, *_args)
    @user = user

    @edit_password_reset_url = edit_spree_user_password_url(reset_password_token: token)

    mail to: @user.email,
         subject: 'Your password reset link'
  end

  def confirmation_instructions(user, token, *_args)
    @user = user

    @confirmation_instructions_url = confirmation_url(@user, confirmation_token: token)

    mail to: @user.email,
         subject: 'Your confirmation link'
  end

  def welcome_new_user(team, user, password, retailer_id)
    @team = team
    @user = user
    @password = password

    # Currently only for use by retailer
    return unless team.is_a?(Spree::Retailer)

    @retailer = Spree::Retailer.find_by(id: retailer_id)

    mail to: @user.email,
         subject: 'Your Credentials for TeamUp'
  end

  def invite_new_user(team, user, password, retailer_id)
    @team = team
    @user = user
    @password = password

    # Currently only for use by retailer
    return unless team.is_a?(Spree::Retailer)

    @retailer = Spree::Retailer.find_by(id: retailer_id)

    mail to: @user.email,
         subject: 'Your Credentials for TeamUp'
  end

  def add_product_to_shopify
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'Add products to shopify'
  end

  def find_top_seller
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'Find Top Sellers'
  end

  def first_order
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'First order'
  end

  def configure_auto_payment
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'Configure auto payment'
  end

  def review_mxed
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'Review TeamUp'
  end

  def business_advice
    mail to: ENV['OPERATIONS_EMAIL'], subject: 'Business advice'
  end

  def unpaid_orders(retailer)
    @retailer = retailer
    @orders = Spree::Order.remindable_unpaid_orders.where(retailer_id: retailer.id)

    mail to: retailer.email, subject: "You have #{@orders.count} unpaid orders"
    @orders.update_all('payment_reminder_count = payment_reminder_count + 1')
  end
end
