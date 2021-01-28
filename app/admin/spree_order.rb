ActiveAdmin.register Spree::Order do
  require 'open-uri'
  # config.filters = false

  filter :number
  filter :completed_at

  filter :retailer_name_in, label: 'Retailer', as: :string
  filter :supplier_name_in, label: 'Supplier', as: :string
  filter :retailer_order_number_is, label: 'Retailer Shopify Order #', as: :string
  filter :supplier_identifier_is, label: 'Supplier Shopify Identifier', as: :string
  filter :supplier_shopify_name, label: 'Supplier Shopify Name', as: :string
  filter :retailer_shopify_id, label: 'Retailer Shopify Identifier', as: :string
  filter :retailer_shopify_name, label: 'Retailer Shopify Name', as: :string
  # filter :stripe_id, label: 'Stripe ID', as: :string

  actions :all, except: [:destroy]

  scope :in_transit_over_last_30_days
  scope :late
  scope :due_soon
  scope :due_in_24_hours
  scope :shipped_orders
  scope :shipped_or_partially_shipped_orders
  scope :cancelled
  scope :partially_fulfilled
  scope :paid
  scope :unpaid
  scope :international

  menu id: 'Orders'

  collection_action :process_stack_commerce_orders, method: :post do
    long_running_job_params = params[:long_running_job]

    file = long_running_job_params[:file]
    if file.blank?
      redirect_back fallback_location: admin_data_import_export_statuses_path,
                    alert: 'File is required.'
      return
    end

    puts file.inspect

    retailer = Spree::Retailer.find(ENV['INTERNAL_RETAILER_ID'].to_i)

    puts "Processing with Retailer: #{retailer.name}".yellow

    # Create Long Running Job
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'orders_import',
      initiated_by: 'user',
      retailer_id: retailer.id,
      teamable_type: retailer.class.to_s,
      teamable_id: retailer.id,
      input_csv_file: file
    )

    job.save!
    job.reload

    puts "Created JOB #{job.internal_identifier} for Docs".blue

    StackCommerce::OrderImportJob.perform_later(job.internal_identifier)

    redirect_back fallback_location: admin_data_import_export_statuses_path,
                  notice: 'File Processing in Place.'
  end

  collection_action :process_karmaloop_orders, method: :post do
    long_running_job_params = params[:long_running_job]

    file = long_running_job_params[:file]
    if file.blank?
      redirect_back fallback_location: admin_data_import_export_statuses_path,
                    alert: 'File is required.'
      return
    end

    puts file.inspect

    retailer = Spree::Retailer.find(ENV['INTERNAL_RETAILER_ID'].to_i)

    puts "Processing with Retailer: #{retailer.name}".yellow

    # Create Long Running Job
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'orders_import',
      initiated_by: 'user',
      retailer_id: retailer.id,
      teamable_type: retailer.class.to_s,
      teamable_id: retailer.id,
      input_csv_file: file
    )

    job.save!
    job.reload

    puts "Created JOB #{job.internal_identifier} for Docs".blue

    Karmaloop::OrderImportJob.perform_later(job.internal_identifier)

    redirect_back fallback_location: admin_data_import_export_statuses_path,
                  notice: 'File Processing in Place.'
  end

  action_item :download_order_risks, only: :show do
    link_to 'Download Risks', download_order_risks_admin_spree_order_path(spree_order),
            method: :post
  end

  action_item :download_all_orders_risks, only: :index do
    link_to 'Download All Risks', download_all_orders_risks_admin_spree_orders_path,
            method: :post
  end

  member_action :download_order_risks, method: :post do
    order = Spree::Order.find_by(number: params[:id])
    order.redownload_order_risks(current_spree_user)
    flash[:notice] = 'Order risks import initialized'
    redirect_back fallback_location: admin_spree_order_path(order)
  end

  collection_action :download_shipping_compliance, method: :post do
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      hash_option_1: {
        from_date: params[:long_running_job][:from_date],
        to_date: params[:long_running_job][:to_date]
      },
      supplier_id: params[:long_running_job][:supplier_id]
    )

    Csv::Export::OrdersShippingComplianceReportWorker.perform_async(job.internal_identifier)

    flash[:notice] = 'Compliance is being downloaded'
    redirect_back fallback_location: download_shipping_compliance_admin_spree_orders_path
  end

  collection_action :monitor_orders_fulfillment, method: :post do
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'user',
      hash_option_1: {
          from_date: params[:long_running_job][:from_date],
          to_date: params[:long_running_job][:to_date]
      },
      retailer_id: params[:long_running_job][:retailer_id]
    )

    Csv::Export::OrdersFulfillmentMonitoringWorker.perform_async(job.internal_identifier)

    flash[:notice] = 'Orders fulfillment report is being sent via email'
    redirect_back fallback_location: monitor_orders_fulfillment_admin_spree_orders_path
  end

  collection_action :download_all_orders_risks, method: :post do
    Spree::Order.redownload_all_order_risks(current_spree_user)
    flash[:notice] = 'Order risks import initialized'
    redirect_back fallback_location: admin_spree_orders_path
  end

  action_item(:index, only: :index) do
    params.permit!
    link_to 'Download For Email', download_for_email_admin_spree_orders_path(q: params.to_h),
            method: :post
  end

  collection_action :download_for_email, method: :post do
    params.permit!
    job = Spree::LongRunningJob.create!(
      action_type: 'export',
      job_type: 'csv_export',
      initiated_by: 'user',
      user_id: current_spree_user.id,
      option_1: 'Orders By Line Item Download',
      option_2: params[:q].try(:to_json) || '{}'
    )

    Csv::Export::OrdersByLineItemJob.perform_later(job.internal_identifier)

    flash[:notice] = "CSV Export have started in the background. \
          You'll will get an email containing your attachment shortly!"
    redirect_to admin_dashboard_path
  end

  index download_links: false, pagination_total: false do
    column ('Order#') do |o|
      link_to "#{o.number}", admin_spree_order_path(o)
    end
    column :date_created, &:created_at
    column :date_sent, &:shopify_sent_at
    column :retailer
    column :supplier
    column :payment_status, &:payment_state_display
    column :shopify_processing_status, &:shopify_processing_status
    column :shipment_status, &:shipment_state
    column :days_to_ship, &:days_to_ship
  end

  controller do
    def find_resource
      scoped_collection.where(number: params[:id]).first!
    end
  end

  form do |f|
    f.semantic_errors
    inputs do
      input :number
      input :customer_email, as: :email
      input :currency
      input :item_total, min: 0, max: 0
      input :user_id
      input :bill_address_id
      input :ship_address_id
      input :shipment_state
      input :payment_state
      input :store_id
      input :special_instructions
      input :considered_risky
      input :store_id
      input :supplier_shopify_identifier
      input :retailer_shopify_identifier
      input :shopify_logs
      input :retailer_shopify_order_number
      input :retailer_shopify_name
      input :retailer_shopify_number
      input :retailer_id
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :internal_identifier
      row :purchase_order_number
      row :number
      row 'Date Created', &:created_at
      row 'Date Sent', &:shopify_sent_at
      row :retailer
      row :retailer_id
      row :retailer_shopify_order_number
      row :retailer_shopify_name
      row :retailer_shopify_number
      row :supplier
      row 'Supplier Order#', &:supplier_shopify_order_name
      row :shipment_state
      row 'Payment State', &:payment_state_display
      row :shopify_processing_status
      row :days_to_ship
      row 'Total Shipping' do |o|
        span class: 'money' do
          o.total_shipping
        end
      end
      row 'Cost With Shipping' do |o|
        span class: 'money' do
          o.total_cost_price_with_shipping
        end
      end
      row 'Cost Without Shipping' do |o|
        span class: 'money' do
          o.total_cost_price_without_shipping
        end
      end
      row 'Supplier Shopify' do |o|
        url = "https://#{o.supplier.shopify_url}/admin/orders/#{o.supplier_shopify_identifier}"
        link_to 'Open in shopify', url, target: '_blank'
      end
      row 'Retailer Shopify' do |o|
        url = "https://#{o.retailer.shopify_url}/admin/orders/#{o.retailer_shopify_identifier}"
        link_to 'Open in shopify', url, target: '_blank'
      end
      row :supplier_shopify_identifier
      row :retailer_shopify_identifier
      row 'App URL (Retailer)' do |o|
        link_to 'Open in app', retailer_order_details_path(o.internal_identifier), target: '_blank'
      end
      row 'App URL (Supplier)' do |o|
        link_to 'Open in app', supplier_order_details_path(o.internal_identifier), target: '_blank'
      end
      row :risk_recommendation do |spree_order|
        "<span class='status_tag #{spree_order.risk_severity_class}'>"\
        "#{spree_order.risk_recommendation}</span>".html_safe
      end
      row :customer_email, as: :email
      row :currency
      row :user_id
      row :bill_address_id
      row :ship_address_id
      row :shipment_state
      row :store_id
      row :special_instructions
      row :considered_risky
      row :store_id
      row :shopify_logs
      row :shopify_processing_status
      row :risk_recommendation do |spree_order|
        "<span class='status_tag #{spree_order.risk_severity_class}'>"\
        "#{spree_order.risk_recommendation}</span>".html_safe
      end
    end

    panel 'Payments' do
      table_for spree_order.payments do
        column :id
        column 'Credit Card' do |payment|
          card = payment.payment_source
          next 'Not Credit Card' unless card.is_a?(StripeCard)

          card.last_four
        end
        column :amount
        column :state
        column 'Charge ID', :number
      end
    end

    panel 'Order Risks' do
      table_for spree_order.order_risks do
        column :id
        column :message
        column :recommendation
        column :score
        column :source
        column :cause_cancel
        column :display
        column :shopify_identifier
        column :created_at
      end
    end
  end
end
