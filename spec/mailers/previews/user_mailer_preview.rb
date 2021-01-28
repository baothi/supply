# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/invite_new_user
  def invite_new_user
    retailer = Spree::Retailer.last
    UserMailer.invite_new_user(conn.supplier, Spree::User.last, 'password', retailer)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/welcome_new_user
  def welcome_new_user
    retailer = Spree::Retailer.last
    UserMailer.welcome_new_user(Spree::Retailer.last, Spree::User.last, 'password', retailer)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/reset_password_instructions
  def reset_password_instructions
    mailer_params = { retailer_id: Spree::Retailer.last.id }
    UserMailer.reset_password_instructions(Spree::User.last, 'password-reset-token', mailer_params)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/confirmation_email
  def confirmation_email
    UserMailer.confirmation_instructions(Spree::User.first, 'xxxxxx', {})
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/add_product_to_shopify
  def add_product_to_shopify
    UserMailer.add_product_to_shopify
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/find_top_seller
  def find_top_seller
    UserMailer.find_top_seller
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/first_order
  def first_order
    UserMailer.first_order
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/configure_auto_payment
  def configure_auto_payment
    UserMailer.configure_auto_payment
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/review_mxed
  def review_mxed
    UserMailer.review_mxed
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/business_advice
  def business_advice
    UserMailer.business_advice
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/unpaid_orders
  def unpaid_orders
    UserMailer.unpaid_orders(Spree::Retailer.first)
  end
end
