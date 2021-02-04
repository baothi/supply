Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'testing/generate_orders/:teamable/:team_id', to: 'testing#generate_orders'
  get 'testing/status/generation/:job_identifier', to: 'testing#generation_status', as: :generation_status
  get 'testing/sync_shopify_products/:supplier_id', to: 'testing#sync_shopify_products'
  get 'testing/status/sync_shopify_products/:job_identifier', to: 'testing#sync_status', as: :sync_status

  mount ActionCable.server => '/cable'
  mount Spree::Core::Engine, at: '/storefront'
  Spree::Core::Engine.add_routes do
    root to: redirect('/'), as: :authenticated_root
  end
  get '/storefront/admin' => 'spree/admin/products#index'

  namespace :webhooks do
    post 'stripe' => 'stripe#index'
    post 'shopify/:teamable_type/:team_identifier', to: 'shopify#index'
    post 'gdpr', to: 'shopify#gdpr'
    # get 'shopify/test' => 'shopify#test'
    post 'hellosign' => 'hello_sign#callback'
  end

  get 'browser-not-supported' => 'home#browser_not_supported', as: :browser_not_supported

  devise_for :spree_users,
             path: '',
             class_name: 'Spree::User',
             controllers: {
                 sessions: 'sessions',
                 passwords: 'passwords',
                 confirmations: 'confirmations'
             },
             path_names: { sign_in: 'login', signUp: '', sign_out: 'logout' }

  # constraints CanAccessManagementTools do

  devise_scope :admin_user do
    get 'active/admin/login' => 'admin/devise/sessions#new', :as => :new_admin_user_session
    get 'active/admin/logout' => 'active_admin/devise/sessions#destroy',
        :as => :destroy_admin_user_session
  end

  flipper_block = lambda do
    Dropshipper.flipper
  end

  scope :active do
    devise_config = ActiveAdmin::Devise.config
    devise_config[:controllers][:omniauth_callbacks] = 'omniauth_callbacks'
    devise_config[:skip] = [:sessions]
    devise_for :admin_users, devise_config

    ActiveAdmin.routes(self)
    get 'export_csv', to: 'admin/bulk_export#csv', as: :export_csv
    get 'update_image_counter',
        to: 'admin/bulk_product#update_image_counter',
        as: :update_image_counter
    get 'update_product_cache',
        to: 'admin/bulk_product#update_product_cache',
        as: :update_product_cache
    # Categories
    get 'update_product_categories/:id',
        to: 'admin/bulk_product#update_product_categories',
        as: :update_product_categories
    get 'export_dsco_orders/:id',
        to: 'admin/bulk_export#dsco_orders',
        as: :export_dsco_orders
    get 'map_product_categories/:id',
        to: 'admin/bulk_product#map_product_categories',
        as: :map_product_categories
    # Colors
    get 'update_product_colors/:id',
        to: 'admin/bulk_product#update_product_colors',
        as: :update_product_colors
    get 'map_product_colors/:id',
        to: 'admin/bulk_product#map_product_colors',
        as: :map_product_colors
    # Sizes
    get 'update_product_sizes/:id',
        to: 'admin/bulk_product#update_product_sizes',
        as: :update_product_sizes
    get 'map_product_sizes/:id',
        to: 'admin/bulk_product#map_product_sizes',
        as: :map_product_sizes
  end

  authenticate :admin_user do
    mount Flipper::UI.app(flipper_block) => '/flipper'

    require 'sidekiq/web'
    # require 'sidekiq-pro'
    # require 'sidekiq/pro/web'
    require 'sidekiq-status/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: '/letter-opener'
  end

  root 'home#index'
  # root to: "devise/sessions#new"

  # Registration
  #
  # get '/register/supplier' => 'registration#supplier'
  # post '/register/supplier' => 'registration#create_supplier'
  # get 'register/onboard' => 'registration#onboard'

  # Dashboard
  get 'dashboard/' => 'dashboard#index'
  get '/dashboard2' => 'dashboard#index_two'
  # Compliance
  get 'compliance/' => 'compliance#index'

  # Invoices
  get 'invoices/' => 'invoices#index'
  get 'invoices/details' => 'invoices#details'

  # Reporting
  get 'reporting/' => 'reporting#index'
  get 'reporting/sales_by_product' => 'reporting#sales_by_product'
  get 'reporting/sales_by_supplier' => 'reporting#sales_by_supplier'
  # get "reporting/sales_by_sku" => "reporting#sales_by_sku"
  get 'reporting/sales_by_period' => 'reporting#sales_by_period'
  get 'reporting/sales_by_day' => 'reporting#sales_by_day'
  get 'reporting/sales_by_month' => 'reporting#sales_by_month'
  get 'reporting/settlement' => 'reporting#settlement'

  # Supplier Application
  get 'supplier_application/' => 'supplier_application#index'
  get 'supplier_application/step_two' => 'supplier_application#step_two'
  get 'supplier_application/confirmation' => 'supplier_application#confirmation'
  # Supplier Onboarding
  # get 'supplier_onboarding/' => 'supplier_onboarding#basic_information'
  # get 'supplier_onboarding/basic_information' => 'supplier_onboarding#basic_information'
  # get 'supplier_onboarding/payment_information' => 'supplier_onboarding#payment_information'
  # get 'supplier_onboarding/contact_information' => 'supplier_onboarding#contact_information'
  # get 'supplier_onboarding/customer_service' => 'supplier_onboarding#customer_service'
  # get 'supplier_onboarding/seller_agreement' => 'supplier_onboarding#seller_agreement'
  # get 'supplier_onboarding/completed' => 'supplier_onboarding#completed'
  # Profile
  get '/profile', to: 'profiles#index'
  patch '/profile/switch-team/:internal_identifier', to: 'profiles#switch_team'

  # Sidebar
  get 'site-sidebar.tpl' => 'dashboard#sidebar'

  # Impersonation
  resources :impersonation, only: [] do
    patch :impersonate
    patch :stop_impersonating, on: :collection
  end

  # Fake Endpoints for Fulfillment Service
  get 'fetch_tracking_numbers/' => 'supplier/shopify#fetch_tracking_numbers'
  get 'fetch_stock' => 'supplier/shopify#fetch_stock'

  get 'shopify/install' => 'shopify#install'

  # Plans
  namespace :pricing_plan do
  end

  get 'pricing_plan/:role/success' => 'pricing_plan#success', as: :pricing_plan_success
  get 'pricing_plan/:role/:plan_id' => 'pricing_plan#index', as: :pricing_plan

  post 'settings/send_confirmation_instructions_notification' => 'home#send_confirmation_instructions_notification', as: :resend_email_confirmation_instructions
  post 'settings/mark_appointment_as_scheduled' => 'home#mark_appointment_as_scheduled', as: :mark_appointment_as_scheduled

  # get 'pricing_plan/initiate_session/:plan_id' => 'pricing_plan#initiate_session'

  # Retailer Controllers
  namespace :supplier do
    get '/' => 'dashboard#index'
    get '/dashboard' => 'dashboard#index'

    get 'onboarding/' => 'onboarding#index'

    get '/shopify/initiate' => 'shopify#initiate'
    get '/shopify/i/n/i/t/iate' => 'shopify#secret_initiate'
    get 'shopify/install' => 'shopify#install'
    get '/shopify/auth' => 'shopify#auth'

    get '/shopify_login' => 'shopify#shopify_login'
    get '/shopify_login_success' => 'shopify#shopify_login_success'
    get 'shopify/login/callback', to: 'shopify#shopify_login_callback'

    # Shopify Integration
    get 'shopify/sync/products', to: 'sync#sync_products', as: :sync_shopify_products
    get 'shopify/import-collection-products-modal',
        to: 'sync#import_collection_products_modal',
        as: :import_collection_products_modal
    post 'shopify/import-collection-products',
         to: 'sync#import_collection_products',
         as: :import_collection_products
    delete 'shopify/disconnect', to: 'sync#disconnect', as: :disconnect_shopify

    # Integrations
    get 'integrations/' => 'integrations#index'
    get 'integrations/shopify' => 'integrations#shopify'
    get 'integrations/edi' => 'integrations#edi'
    get 'integrations/sftp' => 'integrations#sftp'
    get 'integrations/dsco' => 'integrations#dsco'
    post 'integrations/shopify' => 'integrations#update_shopify'
    patch 'integrations/shopify' => 'integrations#update_shopify'

    # Long Running Jobs
    get 'jobs/' => 'jobs#index'
    get 'jobs/history' => 'jobs#history'
    get 'jobs/recurring' => 'jobs#recurring'
    get 'jobs/imports' => 'jobs#imports'
    get 'jobs/exports' => 'jobs#exports'
    get 'jobs/errors' => 'jobs#errors'
    get 'jobs/details/:id' => 'jobs#details', as: :jobs_details
    get 'jobs/download_csv/:id' => 'jobs#download_csv', as: :download_csv

    # Orders
    get 'orders/' => 'orders#index'
    get 'orders/reported' => 'orders#reported'
    get 'orders/details/:id' => 'orders#details', as: :order_details
    post 'orders/reported' => 'orders#report_decision', as: :order_report_decision
    patch 'orders/fulfill_line_item/:order_id' => 'orders#fulfill_line_item',
          as: :fulfill_line_item
    get 'orders/import-fulfillment/:order_id' => 'orders#import_fulfillment',
        as: :import_order_fulfillment

    get 'orders/cancel-line-item' => 'orders#cancel_line_item', as: :cancel_line_item
    get 'orders/refund-line-item' => 'orders#refund_line_item', as: :refund_line_item

    # Products
    get 'products' => 'products#index'
    get 'products/details/:id' => 'products#details', as: :product_details

    # Product Compliance
    get 'product_compliance/' => 'product_compliance#index'

    # Shipping Option Management -
    get 'settings/shipping_methods' => 'shipping_methods#index',
        as: :shipping_methods
    get 'settings/shipping_methods/:service_code' => 'shipping_methods#show',
        as: :shipping_methods_details
    post 'settings/shipping_methods/update_mapping/:service_code' =>
             'shipping_methods#update_mapping',
         as: :update_shipping_method_mapping

    # Referrals
    get 'add_referral' => 'referrals#new'
    post 'referrals' => 'referrals#create'
    get 'referrals' => 'referrals#index'

    # Payment
    get 'onboarding/' => 'onboarding#index'
    get 'select_plan/' => 'select_plan#index'

    get 'word_press/' => 'word_press#index'
    post 'word_press/update_product/' => 'word_press#update_product'

    get 'word_press/update_ckcs/' => 'word_press#update_ckcs'
    patch 'word_press/update_keyapi/' => 'word_press#update_keyapi'
    # namespace :word_press do
    # end

    namespace :settings do
      get :shopify
      get :pricing
      post :update
    end

    namespace :settings do
      get 'my_account/' => 'my_account#index'
      patch 'update_account/' => 'my_account#update_account'
      patch 'update_email/' => 'my_account#update_email'

      # Password Management
      get 'password/' => 'my_account#password'
      patch 'update_password/' => 'my_account#update_password'
    end

    scope :settings do
      resources :team, only: :index do
        collection do
          get :member, path: 'member/:internal_identifier'
          post :add_account
          patch :update_account
          patch :delete_account
        end
      end
    end
  end

  # Retailer Controllers
  namespace :retailer do
    match '/unsubscribe/:unsubscribe_hash' => "emails#unsubscribe", as: "unsubscribe", via: :all
    get '/dashboard/out_of_stock' => 'dashboard#out_of_stock'
    get '/dashboard/back_in_stock' => 'dashboard#back_in_stock'
    get '/dashboard/deactivated_products' => 'dashboard#deactivated_products'

    # Help
    get 'help/overview' => 'help#overview'
    get 'help/download_guide' => 'help#download_guide'

    # Shopify Integrations

    get 'integrations/shopify' => 'integrations#shopify'
    delete 'shopify/disconnect', to: 'sync#disconnect', as: :disconnect_shopify

    get 'onboarding/' => 'onboarding#index'
    get 'onboarding/begin_selling' => 'onboarding#begin_selling'

    get '/' => 'dashboard#index'
    get '/dashboard' => 'dashboard#index', as: :dashboard
    get '/dashboard2' => 'dashboard#index_two'

    # Install Shopify App
    get '/shopify/initiate' => 'shopify#initiate', as: :install_shopify_app
    get '/shopify/i/n/i/t/iate' => 'shopify#secret_initiate'
    get 'shopify/install' => 'shopify#install'
    get '/shopify/auth' => 'shopify#auth'

    get '/shopify_login' => 'shopify#shopify_login'
    get '/shopify_login_success' => 'shopify#shopify_login_success'
    get 'shopify/login/callback', to: 'shopify#shopify_login_callback'

    # Shopify Billing
    get '/shopify/billing/create', to: 'shopify_recurring_charge#create', as: :create_recurring_charge
    get '/shopify/billing/callback', to: 'shopify_recurring_charge#callback', as: :recurring_charge_callback

    # Fulfillment service
    get 'shopify/fetch_stock' => 'shopify#fetch_stock'

    # Orders
    get 'orders/' => 'orders#index'
    get 'orders/samples' => 'orders#samples'
    get 'orders/archived' => 'orders#archived'
    get 'orders/bulk_payment' => 'orders#bulk_payment'
    get 'orders/manual-import' => 'orders#manual_import'
    get 'orders/reported' => 'orders#reported'
    get 'orders/manual_variant_finder' => 'orders#manual_variant_finder'
    get 'orders/diagnosis' => 'orders#diagnosis', as: :order_diagnosis
    get 'orders/find-shopify-order' => 'orders#find_shopify_order'
    get 'orders/manual-import' => 'orders#manual_import', as: :manual_order_import
    post 'orders/manual-import' => 'orders#order_import'
    get 'orders/diagnose' => 'orders#diagnose'
    get 'orders/details/:id' => 'orders#details', as: :order_details
    get 'orders/switch_card' => 'orders#switch_card'
    post 'orders/pay' => 'orders#pay'
    post 'orders/batch-action' => 'orders#batch_action'
    get 'orders/remove-line-item' => 'orders#remove_line_item', as: :remove_line_item
    get 'orders/cancel_order/:order_id' => 'orders#cancel_order', as: :cancel_order
    get 'orders/cancel-line-item' => 'orders#cancel_line_item', as: :cancel_line_item
    get 'orders/refund-line-item' => 'orders#refund_line_item', as: :refund_line_item

    get 'orders/remove_shipping_and_set_cost_to_11/:order_id/:amount_in_cents' =>
            'orders#remove_shipping_and_set_cost',
        as: :remove_shipping_and_set_cost

    get 'orders/all_cards' => 'orders#all_cards'
    get 'orders/import-fulfillment/:order_id' => 'orders#import_fulfillment',
        as: :import_order_fulfillment
    get 'orders/export-fulfillment/:order_id' => 'orders#export_fulfillment',
        as: :export_order_fulfillment
    patch 'orders/fulfill_line_item/:order_id' => 'orders#fulfill_line_item',
          as: :fulfill_line_item
    get 'orders/remit-to-shopify/:order_id' => 'orders#remit_to_shopify',
        as: :remit_to_shopify
    get 'orders/remit-to-dsco/:order_id' => 'orders#remit_to_dsco',
        as: :remit_to_dsco
    get 'orders/replace-discontinued-line-items/:order_id',
        to:  'orders#replace_discontinued_line_items', as: :replace_discontinued_line_items
    post 'orders/import' => 'orders#import'
    post 'orders/clear_errors' => 'orders#clear_errors'

    get 'orders/reset_remittance/:order_id' => 'orders#reset_remittance',
        as: :reset_remittance
    get 'orders/set_free_shipping/:order_id' => 'orders#set_free_shipping',
        as: :set_free_shipping
    get 'orders/update-order-risks/:order_id' => 'orders#update_order_risks',
        as: :update_order_risks
    get 'orders/issue-full-refund/:order_id' => 'orders#issue_full_refund',
        as: :issue_full_refund

    get 'orders/delete_order/:order_id' => 'orders#delete_order',
        as: :delete_order
    get 'orders/edit-line-items/:order_id' => 'orders#edit_line_items',
        as: :edit_order_line_items
    post 'orders/replace-line-items/:order_id' => 'orders#replace_line_items',
         as: :replace_order_line_items

    post 'orders' => 'orders#new_card'
    get 'orders/issue-report/:id/open-modal' => 'orders#open_issue_report_modal',
        as: :open_issue_report_modal,
        defaults: { format: :js }
    post 'orders/error-report' => 'orders#save_order_issue_report', as: :save_order_issue_report

    # Invoices
    get 'invoices/' => 'invoices#index'
    get 'invoices/orders' => 'invoices#orders'
    get 'invoices/details' => 'invoices#details'

    # Products
    get 'products/hydrate' => 'products#hydrate'
    get 'products/' => 'products#index'
    get 'products/inventory' => 'products#inventory'
    get 'products/new' => 'products#new'
    get 'products/list' => 'products#list'
    get 'products/live' => 'products#live', as: :live_products
    get 'products/in_progress' => 'products#in_progress', as: :in_progress
    get 'products/favorites' => 'products#favorites'
    get 'products/followings' => 'products#followings'
    get 'products/get_variants', to: 'products#get_variants'
    get 'products/:product_id/details', to: 'products#details',
                                        as: :product_details
    get 'products/by_license' => 'products#by_license',
        as: :products_by_license
    get 'products/by_license/:license/list',
        to: 'products#list_by_license',
        as: :list_products_by_license
    get 'products/by-license/:license/category/:c',
        to: 'products#category_for_license',
        as: 'category_for_license'
    get 'products/by_license_group/:slug',
        to: 'products#list_license_by_group',
        as: 'list_license_by_group'

    get 'products/by-supplier' => 'products#by_supplier'
    get 'products/by-supplier/:supplier/list',
        to: 'products#list_by_supplier',
        as: :list_products_by_supplier
    get 'products/by-supplier/:supplier/category/:c',
        to: 'products#category_for_supplier',
        as: 'category_for_supplier'

    get 'products/by-category' => 'products#by_category'
    get 'products/by-category/:category/list',
        to: 'products#list_by_category',
        as: :list_products_by_category
    get 'products/by-category/:category/license/:l',
        to: 'products#license_for_category',
        as: 'license_for_category'

    get 'products/by-custom-collection/:collection/list',
        to: 'products#list_by_custom_collection',
        as: :list_products_by_custom_collection
    get 'products/by-custom-collection/:collection/license/:l',
        to: 'products#license_for_custom_collection',
        as: 'license_for_custom_collection'
    get 'products/by-custom-collection/:collection/category/:c',
        to: 'products#category_for_custom_collection',
        as: 'category_for_custom_collection'

    get 'products/:id' => 'products#show'
    get 'products/image_upload' => 'products#image_upload'
    post 'products/image_upload' => 'products#image_upload'
    get 'products/:product_id/favorite' => 'products#add_to_favorites',
        as: :add_to_favorites
    get 'products/:product_id/sync_images' => 'products#sync_images',
        as: :sync_images
    get 'products/:product_id/resync_product' => 'products#resync_product',
        as: :resync_product
    get 'products/:product_id/download_images' => 'products#download_images',
        as: :download_images
    get 'products/:product_id/buy' => 'products#buy_sample',
        as: :buy_sample_product
    get 'products/:product_id/remove-favorite' => 'products#remove_favorite',
        as: :remove_favorite
    get 'products/:product_id/add_to_shopify/' => 'products#add_to_shopify',
        as: :add_to_shopify
    get 'products/:product_id/cancel_export/' => 'products#cancel_export',
        as: :cancel_export
    get 'products/:product_id/remove-listing/' => 'products#delete_from_shopify',
        as: :delete_from_shopify

    # Settings
    post 'settings/' => 'settings#index'
    get 'settings/' => 'settings#shopify_settings'
    get 'settings/shopify-settings' => 'settings#shopify_settings'
    get 'settings/auto-update-settings' => 'settings#auto_update',
        as: :auto_update_settings
    get 'settings/global-margin-rules' => 'settings#global_margin_rules',
        as: :margin_rules_settings
    get 'settings/policies-faq' => 'settings#policies_faq'
    get 'settings/commission_structure' => 'settings#commission_structure'
    get 'settings/users' => 'settings#users'
    get 'settings/user_settings' => 'settings#user_settings'
    get 'settings/accounting' => 'settings#accounting'
    get 'settings/shipping' => 'settings#shipping'
    get 'settings/shopify_login' => 'settings#shopify_login'
    get 'settings/shopify/login/callback',
        to: 'settings#shopify_login_callback'
    get 'settings/billing_information' => 'settings#billing_information'

    # Suppliers
    get 'suppliers' => 'suppliers#index'

    # Referrals
    get 'add_referral' => 'referrals#new'
    post 'referrals' => 'referrals#create'
    get 'referrals' => 'referrals#index'

    # Payment
    # constraints UsingShopifyBillingAPI do
      get 'select_shopify_plan/' => 'shopify_select_plan#index'
    # end
    # constraints UsingStripeBilling do

      get 'select_plan/' => 'select_plan#index'
    # end
    # word_press
    get 'word_press/' => 'word_press#index'

    namespace :settings do
      get 'my_account/' => 'my_account#index'
      patch 'update_account/' => 'my_account#update_account'
      patch 'update_retailer_account/' => 'my_account#update_retailer_account'
      patch 'update_email/' => 'my_account#update_email'

      # Password Management
      get 'password/' => 'my_account#password'
      patch 'update_password/' => 'my_account#update_password'
    end

    # Payments
    resources :payments, only: :index do
      collection do
        post :save_billing_card
        patch :mark_card_as_default
        delete :remove_billing_card
        post :update_plan_subscription
        post :new_card
      end
    end

    scope :settings do
      resources :team, only: :index do
        collection do
          get :member, path: 'member/:internal_identifier'
          post :add_account
          patch :update_account
          patch :delete_account
        end
      end

      resources :addresses, only: :index do
        collection do
          match :update_address, path: '/update-address/:address_type', via: %i(post patch)
          get :update_shopify_address
          get :get_shopify_locations
          post :set_default_shopify_location
        end
      end
    end

    namespace :settings do
      resources :advanced, only: :index do
        collection do
          post :transfer_ownership, path: 'transfer-ownership'
        end
      end

      resources :orders, only: :index do
        collection do
          post :retailer_auto_payment_setting
        end
      end
    end

    resources :taxons, only: [] do
      member do
        post :follow_unfollow
        post :add_products_to_shopify
      end
    end
  end

  resources :sign_up
end
