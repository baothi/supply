ActiveAdmin.register Spree::Retailer do
  includes :users

  scope :has_paid_and_completed_onboarding
  scope :paying_subscriber_and_has_not_completed_onboarding
  scope :awaiting_access
  scope :having_access

  actions :all, except: [:destroy]

  menu label: 'Retailers', parent: 'Teams'
  # config.filters = false

  # filter :id, label: 'Retailer ID', as: :number
  filter :shopify_url, label: 'Shopify URL (e.g. xxx.myshopify.com)', as: :string
  filter :domain, label: 'Custom Domain Name', as: :string
  filter :email, label: 'Owner Email', as: :string
  filter :id, label: 'Store ID'

  controller do
    def find_resource
      scoped_collection.where(slug: params[:id]).first!
    end

    def update
      puts permitted_params.inspect
      resource.update(permitted_params[:retailer])
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def permitted_params
      params.permit(retailer:
                        %i(can_view_supplier_name
                           default_us_shipping_method_id
                           default_canada_shipping_method_id
                           default_rest_of_world_shipping_method_id
                           can_view_brand_name))
    end
  end

  index download_links: false, pagination_total: false do
    selectable_column
    column :id
    column :name do |retailer|
      link_to retailer.name, admin_spree_retailer_path(retailer)
    end
    # column :shop_owner
    column :shopify_url do |retailer|
      next unless retailer.shopify_url.present?

      link_to retailer.shopify_url, "http://#{retailer.shopify_url}", target: '_blank'
    end
    column :plan_name
    column :domain
    # column 'Users' do |retailer|
    #   retailer.users.count
    # end
    # column 'Referrals count', &:number_of_referrals
    column 'Orders' do |retailer|
      retailer.orders.count
    end
    column 'Product Listings' do |retailer|
      # link_to retailer.product_listings.count, admin_spree_product_listings_path
      retailer.product_listings.count
    end
    column 'Installed At', &:created_at
    column :active
    column :access_granted_at
    column :completed_onboarding_at

    actions
  end

  action_item :disable_payments, only: :show do
    link_to 'Disable Payments', action: :disable_payments unless spree_retailer.disable_payments
  end

  action_item :enable_payments, only: :show do
    link_to 'Enable Payments', action: :enable_payments if spree_retailer.disable_payments
  end

  action_item :grant_access, only: :show do
    link_to "#{spree_retailer.access_granted? ? 'Revoke' : 'Grant'} access", action: :grant_access
  end

  action_item :grant_onboarding, only: :show do
    link_to "#{spree_retailer.completed_onboarding? ? 'Revert' : 'Mark as Complete'} Onboarding",
            action: :grant_onboarding
  end

  # TODO: This can be enabled later, when we'd need to have active/inactive users handled from admin
  # action_item :toggle_retailer_activation, only: :show do
  #   link_to "Set Retailer #{spree_retailer.active? ? 'Inactive' : 'Active'}",
  #           action: :toggle_retailer_activation, active: !spree_retailer.active?
  # end

  member_action :look_for_ghost_orders, method: :get do
    resource.look_for_missing_orders

    redirect_to resource_path(resource),
                notice: I18n.t('active_admin.hint.looking_for_ghost_orders')
  end

  member_action :run_shopify_inventory_audit, method: :get do
    resource.generate_inventory_audit_file

    redirect_to resource_path(resource),
                notice: I18n.t('active_admin.hint.shopify_inventory_audit')
  end

  member_action :disable_payments, method: :get do
    retailer = Spree::Retailer.find_by(slug: params[:id])

    if retailer.update(disable_payments: true)
      redirect_to :back, notice: 'Payments Disabled'
    else
      redirect_to :back, notice: 'An error Occured: Payments Could not be Disabled'
    end
  end

  member_action :enable_payments, method: :get do
    retailer = Spree::Retailer.find_by(slug: params[:id])

    if retailer.update(disable_payments: false)
      redirect_to :back, notice: 'Payments Enabled'
    else
      redirect_to :back, notice: 'An error Occured: Payments Could not be Enabled'
    end
  end

  member_action :grant_access, method: :get do
    begin
      retailer = Spree::Retailer.find_by!(slug: params[:id])
      access   = retailer.access_granted? ? :revoke : :grant
      retailer.__send__("#{access}_access!")
      redirect_to :back, notice: "Access #{retailer.access_granted? ? 'Granted' : 'Revoked'}"
    rescue ActiveRecord::RecordNotFound => e
      redirect_to :back, notice: e.message
    end
  end

  member_action :grant_onboarding, method: :get do
    begin
      retailer = Spree::Retailer.find_by!(slug: params[:id])
      access   = retailer.completed_onboarding? ? :remove : :complete
      retailer.__send__("#{access}_onboarding!")
      redirect_to :back,
                  notice: "Onboarding #{retailer.completed_onboarding? ? 'Completed' : 'REverted'}"
    rescue ActiveRecord::RecordNotFound => e
      redirect_to :back, notice: e.message
    end
  end

  # TODO: This can be enabled later, when we'd need to have active/inactive users handled from admin
  # member_action :toggle_retailer_activation, method: :get do
  #   retailer = Spree::Retailer.find_by(slug: params[:id])
  #
  #   if retailer.update(active: params[:active])
  #     redirect_to :back, notice: "Retailer set as
  #     #{retailer.active? ? 'Active' : 'Inactive'}"
  #   else
  #     redirect_to :back, notice: "An error Occured while
  #     #{retailer.active? ? 'activating' : 'deactivating'} Retailer"
  #   end
  # end

  member_action :update_preferences, method: :post do
    params[:retailer][:settings].each do |key, value|
      resource.set_setting(key, value)
    end
    resource.save
    redirect_to resource_path(resource), notice: 'Successfully updated!'
  end

  sidebar 'Onboarding Information', only: :show do
    attributes_table_for spree_retailer do
      row :id
      row :has_stripe_subscription?
      row :current_stripe_subscription_identifier
      row :current_stripe_plan_identifier
      row :completed_onboarding_at
      row :has_shopify_app_installed?
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :email
      row :active
      row :access_granted_at
      row :completed_onboarding_at
      row :disable_payments
      row :ecommerce_platform
      row :facebook_url
      row :instagram_url
      row :website
      row :phone_number
      row :primary_country
      row :tax_identifier_type
      row :shopify_url do |retailer|
        next unless retailer.shopify_url.present?

        link_to retailer.shopify_url, "http://#{retailer.shopify_url}", target: '_blank'
      end
      # row 'Default Address from Shopify', &:default_address
      row :phone
      # row 'Legal Entity Address', &:legal_entity_address
      # row 'Shipping Address', &:shipping_address
      row :shop_owner
      row :plan_name
      row :domain
      row :can_view_supplier_name
      row :can_view_brand_name
      row :order_auto_payment
      row 'Skip Payment For Orders', &:setting_skip_payment_for_orders

      row :orders do |retailer|
        link_to "#{retailer.orders.count} Order(s)", '#'
      end
      # row :suppliers do |retailer|
      #   link_to "#{retailer.suppliers.count} Connected Supplier(s)", '#'
      # end
      row :team_members do |retailer|
        link_to "#{retailer.team_members.count} Team member(s)", '#'
      end
      row 'Product Listings' do |retailer|
        # link_to "#{retailer.product_listings.count} Listing(s)", admin_spree_product_listings_path
        retailer.product_listings.count
      end
      row :favorites do |retailer|
        link_to "#{retailer.favorites.count} Favorite(s)", '#'
      end
      row :follows do |retailer|
        link_to "#{retailer.follows.count} Follow(s)", '#'
      end
      row :shopify_credential do
        link_to 'Shopify Credential', '#'
      end
      row :stripe_customer do |retailer|
        retailer.stripe_customer.present? ? link_to('View Stripe Customer', '#') : 'No Stripe Cards'
      end
      row :created_at
    end

    panel 'Licenses' do
      render 'license_access'
    end

    panel 'Team Members' do
      table_for spree_retailer.users do
        column :confirmed do |user|
          user.confirmed_at.present?
        end
        column :full_name
        column :email
        column :role do |user|
          user.role.name.humanize
        end

        column 'Action' do |user|
          next if user == current_spree_user

          link_to 'impersonate',
                  impersonation_impersonate_path(
                    impersonation_id: user.team_member.internal_identifier
                  ),
                  method: :patch,
                  target: '_blank'
        end
      end
    end

    # panel 'Sales Data' do
    #   table_for spree_retailer.retailer_order_reports do
    #     column :report_generated_at
    #     column :source
    #     column :num_of_orders_last_30_days
    #     column :num_of_orders_last_60_days
    #     column :num_of_orders_last_90_days
    #   end
    # end

    panel 'Settings/Preferences' do
      render 'settings'
    end

    if resource.platform == 'shopify'
      panel 'Missing Orders (Ghost Orders)' do
        para 'This will check the retailers shopify account if they have any missing orders'
        render 'missing_orders'
      end

      panel 'Inventory Audit' do
        para 'This will help run an inventory order for this Shopify retailer'
        render 'inventory_audit'
      end
    end

    attributes_table title: 'Shipping Information' do
      row :default_us_shipping_method
      row :default_canada_shipping_method
      row :default_rest_of_world_shipping_method
    end

    panel 'Brands or Vendor Referrals' do
      table_for Spree::SupplierReferral.where(spree_retailer_id: spree_retailer.id) do
        column :name
        column :url
        column :has_relationship
      end
    end

    active_admin_comments
  end

  form do |f|
    f.inputs 'Details' do
      f.input :id
      f.input :name
      f.input :slug
      f.input :email
      f.input :active
      f.input :disable_payments
      f.input :ecommerce_platform
      f.input :facebook_url
      f.input :instagram_url
      f.input :website
      f.input :phone_number
      f.input :primary_country
      f.input :tax_identifier_type
      f.input :shopify_url
      f.input :legal_entity_address
      f.input :shipping_address
      f.input :phone
      f.input :shop_owner
      f.input :plan_name
      f.input :domain
      f.input :order_auto_payment
      f.input :can_view_supplier_name
      f.input :can_view_brand_name
      f.input :default_us_shipping_method_id,
              as: :select,
              required: true,
              collection: Spree::ShippingMethod.real_shipping_methods,
              hint: I18n.t('active_admin.hint.retailer.us_default_shipping')
      f.input :default_canada_shipping_method_id,
              as: :select,
              required: true,
              collection: Spree::ShippingMethod.real_shipping_methods,
              hint: I18n.t('active_admin.hint.retailer.canada_default_shipping')
      f.input :default_rest_of_world_shipping_method_id,
              as: :select,
              required: true,
              collection: Spree::ShippingMethod.real_shipping_methods,
              hint: I18n.t('active_admin.hint.retailer.rest_of_world_default_shipping')
    end

    f.actions
  end
end
