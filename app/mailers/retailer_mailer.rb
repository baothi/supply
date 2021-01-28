class RetailerMailer < ApplicationMailer
  def welcome(retailer_id)
    @retailer = Spree::Retailer.find(retailer_id)

    mail to: @retailer.email, subject: 'Welcome to TeamUp!'
  end

  def invite_vendors(retailer_id)
    @retailer = Spree::Retailer.find(retailer_id)

    mail to: @retailer.email, subject: 'Invite vendors to move up in priority'
  end


  def retailer_gets_first_sale(retailer_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    mail to: @retailer.email, subject: "Congratulations! "
  end

  def welcome_install_app(retailer_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    @support_email = ENV['SUPPORT_EMAIL']
    mail to: @retailer.email, subject: 'Welcome to TeamUp!'
  end

  def did_not_install_app(email)
    @retailer = Spree::Retailer.find_by_email(email)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    @Unsubscribe = 'did_not_install_app'
    @support_email = ENV['SUPPORT_EMAIL']
    mail to: @retailer.email, subject: 'Welcome to TeamUp!'
  end

  def retailer_not_sold_any_products_in_7days(retailer_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    @Unsubscribe = 'retailer_not_sold_any_products_in_7days'
    @support_email = ENV['SUPPORT_EMAIL']
    mail to: @retailer.email, subject: 'Let’s get some sales!'
  end

  def did_not_add_product(retailer_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    @Unsubscribe = 'did_not_add_product'
    @support_email = ENV['SUPPORT_EMAIL']
    mail to: @retailer.email, subject: ' Let’s get your store stocked!'
  end

  def did_not_add_more_than_ten_product(retailer_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    @Unsubscribe = 'did_not_add_more_than_ten_product'
    @support_email = ENV['SUPPORT_EMAIL']
    mail to: @retailer.email, subject: 'Let’s get your store stocked!'
  end

  def send_email_when_retailer_created_first_product(retailer_id, supplier_id, product_id)
    @retailer = Spree::Retailer.find_by_id(retailer_id)
    @first_name = "TeamUp Retailer" # Spree::User.find_by(email: @retailer.email).first_name || "TeamUp Retailer"
    mail to: @retailer.email, subject: "You’re on your way!"
  end

  def send_email_stock_status_changed(bcc_email, product_name,internal_identifier,item_tracking_state)
    @product_name = product_name
    @state = item_tracking_state
    @internal_identifier = internal_identifier
    @first_name = "TeamUp Retailer"

    if @state == 'outstock'
      subject = 'Low Stock Alert!'
    else
      subject = 'Back in Stock!'
    end
    mail(to: ENV['SUPPORT_EMAIL'],
        subject: subject,
        bcc: bcc_email)
  end


  def customers_data_request(email,total_order)
    @email = email
    @total_order = total_order
    mail to: @email, subject: "Customer Data"
  end

  def send_mail_deactivated_product(product_internal_identifier,product_name,bcc_email)
    @first_name = "TeamUp Retailer"
    @product_internal_identifier = product_internal_identifier
    @product_name = product_name
    mail(to: ENV['NOREPLY_EMAIL'],
        subject: 'Invite vendors to move up in priority',
        bcc: bcc_email)

  end

end
