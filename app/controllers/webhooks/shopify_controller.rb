class Webhooks::ShopifyController < ActionController::Base
  include CommitWrap

  # protect_from_forgery with: :exception, except: :index
  before_action :set_team, only: :index
  before_action :set_topic, only: [:index, :gdpr]

  def data_object
    @data = request.raw_post
  end

  def index
    return if @team.nil? || @topic.nil?

    # puts 'Webhook Received!'.yellow if Rails.env.development?
    # puts "#{request.raw_post}".blue if Rails.env.development?

    @data = data_object
    return unless verify_webhook(@data, request.headers['HTTP_X_SHOPIFY_HMAC_SHA256'])

    case @topic
    when 'orders/create'
      import_order
    when 'orders/updated'
      update_order_risks
    # when 'products/create'
    #   import_product
    when 'products/delete'
      delete_product
    # when 'products/update'
    #   update_product
    when 'orders/fulfilled', 'orders/partially_fulfilled',
        'fulfillments/create', 'fulfillments/update'
      fulfill_order
    when 'app/uninstalled'
      set_uninstalled_at
    end
  end

  def gdpr
    return if @topic.nil?

    @data = data_object
    return unless verify_webhook(@data, request.headers['HTTP_X_SHOPIFY_HMAC_SHA256'])

    case @topic
    when 'customers/redact'
      customers_redact
    when 'shop/redact'
      shop_redact
    when 'customers/data_request'
      customers_data_request
    end
  end

  private

  def set_team
    internal_identifier = params[:team_identifier]
    @teamable_type =
      if params[:teamable_type] == 'supplier'
        'Spree::Supplier'
      elsif params[:teamable_type] == 'retailer'
        'Spree::Retailer'
      end
    @team = @teamable_type.constantize.find_by(internal_identifier: internal_identifier)
  end

  def import_product
    shopify_product = JSON.parse(@data, object_class: OpenStruct)

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_1: 'webhook',
      option_2: @data,
      option_4: shopify_product.id,
      supplier_id: @team.id,
      teamable_type: @teamable_type,
      teamable_id: @team.id
    )
    Shopify::ProductImportWorker.perform_async(job.internal_identifier)
    head :ok, content_type: 'text/html'
  end

  def update_product
    shopify_product = JSON.parse(@data, object_class: OpenStruct)

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_1: 'webhook',
      option_2: @data,
      option_4: shopify_product.id,
      supplier_id: @team.id,
      teamable_type: @teamable_type,
      teamable_id: @team.id
    )
    Shopify::ProductUpdateWorker.perform_async(job.internal_identifier)
    head :ok, content_type: 'text/html'
  end

  def delete_product
    shopify_product = JSON.parse(@data, object_class: OpenStruct)

    if @teamable_type == 'Spree::Supplier'
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        option_1: 'webhook',
        option_4: shopify_product.id,
        supplier_id: @team.id,
        teamable_type: @teamable_type,
        teamable_id: @team.id
      )
      Shopify::ProductDeleteJob.perform_later(job.internal_identifier)
    elsif @teamable_type == 'Spree::Retailer'
      product_listing = Spree::ProductListing.find_by(shopify_identifier: shopify_product.id)
      return unless product_listing.present?

      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        option_1: product_listing.internal_identifier,
        retailer_id: @team.id,
        teamable_type: @teamable_type,
        teamable_id: @team.id
      )
      Shopify::ProductLiveRemovalJob.perform_later(job.internal_identifier)
    end
    head :ok, content_type: 'text/html'
  end

  def import_order
    shopify_order = JSON.parse(@data, object_class: OpenStruct)

    raise 'This endpoint is only valid for retailers' unless
        @teamable_type == 'Spree::Retailer'

    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'orders_import',
        initiated_by: 'system',
        retailer_id: @team.id,
        supplier_id: nil,
        teamable_type: @teamable_type,
        teamable_id: @team.id,
        option_1: 'webhook',
        option_4: shopify_order.id,
        setting_attempt_auto_pay: true,
        input_data: @data
      )

      execute_after_commit do
        ShopifyOrderImportJob.perform_later(job.internal_identifier)
      end
    end

    head :ok, content_type: 'text/html'
  end

  def fulfill_order
    case @topic
    when 'orders/fulfilled', 'orders/partially_fulfilled'
      shopify_order = JSON.parse(@data, object_class: OpenStruct)
      local_order = Spree::Order.find_by(supplier_shopify_identifier: shopify_order.id)
    when 'fulfillments/create', 'fulfillments/update'
      shopify_fulfillment = JSON.parse(@data, object_class: OpenStruct)
      local_order = Spree::Order.find_by(supplier_shopify_identifier: shopify_fulfillment.order_id)
    end

    return unless local_order.present?

    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'orders_import',
        initiated_by: 'system',
        teamable_type: @teamable_type,
        teamable_id: @team.id,
        option_1: local_order.internal_identifier,
        input_data: @data
      )
      execute_after_commit do
        ShopifyFulfillmentImportJob.perform_later(job.internal_identifier)
      end
    end

    head :ok, content_type: 'text/html'
  end

  def update_order_risks
    shopify_order = JSON.parse(@data, object_class: OpenStruct)
    local_order = Spree::Order.find_by(retailer_shopify_identifier: shopify_order.id)

    return if local_order.blank?

    raise 'This endpoint is only valid for retailers' unless
      @teamable_type == 'Spree::Retailer'

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'order_risks_import',
      initiated_by: 'system',
      option_4: local_order.id.to_s,
      input_data: @data
    )

    Shopify::OrderRisksImportJob.perform_later(job.internal_identifier)
  end

  def set_uninstalled_at
    shopify_credential = @team.shopify_credential
    shopify_credential.disable_connection!
    puts @team.class.to_s.green
    @team.update_trial_time! if @team.class.to_s == "Spree::Retailer"
    render nothing: true, status: 200
  end

  def set_topic
    @topic = request.env['HTTP_X_SHOPIFY_TOPIC']
  end

  def verify_webhook(data, hmac_header)
    # TODO: Probably should mock this during testing versus
    # adding this line
    return true if Rails.env.development? || Rails.env.test?

    shared_secret = ENV['SHOPIFY_APP_SECRET_KEY']
    digest = OpenSSL::Digest.new('sha256')
    c_hmac = Base64.encode64(OpenSSL::HMAC.digest(
                               digest, shared_secret, data
                             )).strip
    ActiveSupport::SecurityUtils.secure_compare(c_hmac, hmac_header)
  end


  # https://shopify.dev/tutorials/add-gdpr-webhooks-to-your-app
  def customers_redact
    shopify_redact = JSON.parse(@data, object_class: OpenStruct)
    raise 'This endpoint is only valid for retailers' unless
        @teamable_type == 'Spree::Retailer'
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'delete customers',
        job_type: 'delete_customers',
        initiated_by: 'system',
        retailer_id: @team.id,
        supplier_id: nil,
        teamable_type: @teamable_type,
        teamable_id: @team.id,
        option_1: 'webhook',
        option_2: shopify_redact.shop_id,
        option_3: shopify_redact.shop_domain,
        option_4: shopify_redact.customer.id,
        option_5: shopify_redact.customer.email,
        option_5: shopify_redact.customer.phone,
        array_option_1: shopify_redact.orders_to_redact,
        input_data: @data
      )
    execute_after_commit do
        Shopify::CustomersRedactJob.perform_later(job.internal_identifier)
      end
    end

    head :ok, content_type: 'text/html'
  end

  def shop_redact
    shopify_redact = JSON.parse(@data, object_class: OpenStruct)
    raise 'This endpoint is only valid for retailers' unless
        @teamable_type == 'Spree::Retailer'
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'delete customers',
        job_type: 'delete_customers',
        initiated_by: 'system',
        retailer_id: @team.id,
        supplier_id: nil,
        teamable_type: @teamable_type,
        teamable_id: @team.id,
        option_1: 'webhook',
        option_2: shopify_redact.shop_id,
        option_3: shopify_redact.shop_domain,
        input_data: @data
      )
    execute_after_commit do
        Shopify::ShopRedactJob.perform_later(job.internal_identifier)
      end
    end

    head :ok, content_type: 'text/html'
  end

  def customers_data_request
    shopify_redact = JSON.parse(@data, object_class: OpenStruct)
    raise 'This endpoint is only valid for retailers' unless
        @teamable_type == 'Spree::Retailer'
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'delete customers',
        job_type: 'delete_customers',
        initiated_by: 'system',
        retailer_id: @team.id,
        supplier_id: nil,
        teamable_type: @teamable_type,
        teamable_id: @team.id,
        option_1: 'webhook',
        option_2: shopify_redact.shop_id,
        option_3: shopify_redact.shop_domain,
        option_4: shopify_redact.customer.id,
        option_5: shopify_redact.customer.email,
        option_6: shopify_redact.customer.phone,
        option_7: shopify_redact.data_request.id,
        array_option_1: shopify_redact.orders_requested,
        input_data: @data
      )
    execute_after_commit do
        Shopify::CustomersDataRequestJob.perform_later(job.internal_identifier)
      end
    end

    head :ok, content_type: 'text/html'
  end
end
