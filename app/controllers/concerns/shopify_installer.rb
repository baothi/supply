module ShopifyInstaller
  include ShopifyAuth

  SCOPE = %w(read_products write_products read_orders write_orders read_fulfillments
             write_fulfillments read_inventory write_inventory read_locations).freeze

  def login(store, install_redirect_url = nil)
    redirect_url = if install_redirect_url
                     install_redirect_url
                   elsif Spree::Supplier.find_by(shopify_url: store)
                     supplier_shopify_auth_url
                   else
                     retailer_shopify_auth_url
                   end

    shopify_session = ShopifyAPI::Session.new(
      domain: store,
      api_version: ENV['SHOPIFY_API_VERSION'],
      token: nil
    )

    permission_url = shopify_session.create_permission_url(
      SCOPE, redirect_url
    )

    redirect_to permission_url
  end

  def initialize_session(shop)
    shopify_session = ShopifyAPI::Session.new(
      domain: shop,
      api_version: ENV['SHOPIFY_API_VERSION'],
      token: nil
    )

    access_token = shopify_session.request_token(params)
    access_token
  rescue Net::OpenTimeout => e
    flash[:alert] = "Error:: #{e.message}"
    nil
  end

  def set_base_site(shop, access_token)
    ShopifyAPI::Base.clear_session
    return unless access_token.present?

    session = ShopifyAPI::Session.new(
      domain: shop,
      token: access_token,
      api_version: ENV['SHOPIFY_API_VERSION']
    )
    ShopifyAPI::Base.activate_session(session)
  end

  def logout_user_if_necessary
    return if session.delete(:existing_team_integration)

    sign_out(current_spree_user) unless current_spree_user.nil?
  end

  def get_site_email(shop)
    email = shop.email
    email
  end

  def save_address(teamable, shop)
    teamable.address1 = shop.address1
    teamable.address2 = shop.address2
    teamable.city = shop.city
    teamable.state = shop.province_code
    teamable.country = shop.country
    teamable.zipcode = shop.zip
    teamable.phone = shop.phone
    teamable.shop_owner = shop.shop_owner
    teamable.shopify_url = shop.myshopify_domain
    teamable.domain = shop.domain
    teamable.plan_name = shop.plan_name
    teamable.plan_display_name = shop.plan_display_name
    teamable.save!
    teamable
  end

  def locate_teamable(role, shopify_url)
    return current_spree_user.teamable if spree_user_signed_in?

    teamable_klass = "Spree::#{role.camelize}".constantize
    teamable = teamable_klass.where('shopify_url = :shopify_url', shopify_url: shopify_url).first
    teamable
  end

  # Creates Teamable (Supplier or Retailer)
  def create_teamable(role, email, shop)
    # Create Teamable - Supplier or Retailer
    teamable = "Spree::#{role.camelize}".constantize.new
    teamable.email = email
    teamable.name = shop.split('.myshopify.com').first.titleize
    teamable.shopify_url = shop
    teamable.save!

    # Create User
    # TODO: Ensure that this can create a secondary email address if it's already taken
    # otherwise once assigned to multiple teams, we won't know where to log them into
    # unless we change our login flow

    temp_pass = SecureRandom.hex(4)
    teamable_user = Spree::User.where(email: email).first_or_create! do |user|
      user.first_name = 'N/A'
      user.last_name = 'N/A'
      user.shopify_url = shop
      user.password = temp_pass
      user.using_temporary_password = true
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

    [teamable, teamable_user]
  end

  def create_shopify_credentials(teamable, shop, access_token)
    credentials = Spree::ShopifyCredential.create!(
      store_url: shop,
      teamable: teamable,
      access_token: access_token
    )
    credentials
  end

  # After successfully logging in
  # shop - e.g. store.myshopify.com
  # role - retailer vs supplier
  # url - path e.g. retailer_dashboard
  def login_callback(shop, url, role)
    redirect_url = url
    redirect_url = retailer_create_recurring_charge_path if ENV['USE_SHOPIFY_BILLING']

    access_token = initialize_session(shop)
    return if access_token.nil?

    set_base_site(shop, access_token)

    # First Logout in case we are logged in
    logout_user_if_necessary
    # Get email associated with store
    current_shopify_store = ShopifyAPI::Shop.current
    email = get_site_email(current_shopify_store)
    # Find Supplier/Retailer that has this url
    teamable = locate_teamable(role, shop)
    if teamable.nil?
      results = create_teamable(role, email, shop)
      teamable = results[0]
      # team_member = results[1]
    end


    teamable.try(:app_name=, ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME'])
    teamable.save!

    # Save Address
    teamable = save_address(teamable, current_shopify_store)

    # TODO: Setup a retail connection between them.

    raise 'Supplier/Retailer cannot be nil' if teamable.nil?
    # Create/Update shopify credential
    create_or_update_credentials(teamable, shop, access_token)

    flash[:notice] = 'Shopify integration successful.'

    unless spree_user_signed_in?
      # TODO: We should try to locate the current user who initiated
      # the installation process.
      # For now, we can assume we can always just assume they are the first
      # team_member
      team_member = teamable.team_members.first
      raise 'Valid user not found' if team_member.nil?

      # Log them in
      user = team_member.user
      user.update(default_team_member_id: team_member.id)
      sign_in(user)
    end
    
    RetailerMailer.welcome_install_app(teamable.id).deliver_later
    
    redirect_to redirect_url
  end

  def create_or_update_credentials(teamable, shop, access_token)
    credential = teamable.shopify_credential
    if credential.nil?
      credential = create_shopify_credentials(teamable, shop, access_token)
    else
      credential.update(access_token: access_token, store_url: shop, uninstalled_at: nil)
    end

    set_up_webhook_creation_job(credential) unless credential.nil?
    set_up_fulfillment_service(credential) unless credential.nil?
  end

  def set_admins
    Spree::User.all.each do |user|
      admin_role = Spree::Role.where(name: 'admin').first
      Spree::RoleUser.where(
        role_id: admin_role.id,
        user_id: user.id
      ).first_or_create! do |_role_user|
      end
    end
  end

  def set_up_webhook_creation_job(credential)
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      retailer_id: credential.teamable.id,
      teamable_type: credential.teamable.class.to_s,
      teamable_id: credential.teamable.id
    )
    Shopify::WebhookCreationJob.perform_later(job.internal_identifier)
  end

  def set_up_fulfillment_service(credential)
    return unless credential.teamable.is_a?(Spree::Retailer)

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      retailer_id: credential.teamable.id,
      teamable_type: credential.teamable.class.to_s,
      teamable_id: credential.teamable.id
    )
    Shopify::FulfillmentServiceCreationJob.perform_later(job.internal_identifier)
  end
end
