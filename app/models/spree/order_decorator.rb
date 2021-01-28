Spree::Order.class_eval do
  # Internal Identifier
  include InternalIdentifiable
  include Spree::Orders::Sampleable

  include Spree::Orders::Constants

  include Spree::Orders::PurchaseOrderNumberable

  # Shopify Remittance Status State Machine
  include AASM
  include Spree::Orders::StatusStateMachine
  include Spree::Orders::SearchScopes
  include Spree::Orders::Refundable
  include Spree::Orders::Cancelable

  include IntervalSearchScopes
  include Spree::Orders::Reporting # For Reporting

  # ActiveAdmin Custom Search Scopes
  include Spree::Orders::ActiveAdminSearch

  delegate :platform, to: :supplier, prefix: true, allow_nil: true
  delegate :platform, to: :retailer, prefix: true, allow_nil: true

  # After Commit
  using AfterCommitWrap::Helper

  serialize :searchable_attributes, Hash

  has_many :order_invoices
  belongs_to :retailer, inverse_of: :orders
  has_one :retailer_credit, through: :retailer
  belongs_to :supplier
  has_one :order_issue_report, dependent: :destroy
  has_many :order_risks, dependent: :destroy

  after_create :set_compliance_dates

  scope :retailer_name_in, ->(search) { Spree::Order.search_by_retailer_name(search) }
  scope :stripe_id, ->(number) {
    Spree::Order.search_by_stripe_id(number)
  }
  scope :supplier_name_in, ->(search) { Spree::Order.search_by_supplier_name(search) }
  scope :retailer_order_number_is, ->(search) {
    Spree::Order.search_by_retailer_shopify_order_number(search)
  }
  scope :supplier_identifier_is, ->(search) {
    Spree::Order.search_by_supplier_shopify_identifier(search)
  }

  after_commit :retailer_gets_first_sale, on: :create

  IN_TRANSIT = %w(country_check quantity_check payment_remittance order_remittance).freeze
  scope :in_transit_over_last_30_days, -> {
    where(shopify_processing_status: IN_TRANSIT).
      where('spree_orders.updated_at > ?', DateTime.now - 30.days)
  }

  # For ActiveAdmin
  def self.ransackable_scopes(_auth_object = nil)
    %i(retailer_name_in supplier_name_in retailer_order_number_is
       supplier_identifier_is stripe_id stripe_id supplier_shopify_name retailer_shopify_name
       retailer_shopify_id)
  end

  def self.search_by_retailer_name(retailer_name)
    Spree::Order.joins(:retailer).where("spree_retailers.name like '%#{retailer_name}%'")
  end

  def self.search_by_supplier_name(supplier_name)
    Spree::Order.joins(:supplier).where("spree_suppliers.name like '%#{supplier_name}%'")
  end

  def self.search_by_retailer_shopify_order_number(number)
    Spree::Order.where(retailer_shopify_order_number: number)
  end

  def self.search_by_supplier_shopify_identifier(number)
    Spree::Order.where(supplier_shopify_identifier: number)
  end

  def self.search_by_stripe_id(number)
    joins(:payments).where("spree_payments.number LIKE '%#{number}%'")
  end

  def self.retailer_shopify_name(value)
    Spree::Order.where(retailer_shopify_name: value)
  end

  def self.supplier_shopify_name(value)
    Spree::Order.where(supplier_shopify_order_name: value)
  end

  def self.retailer_shopify_id(value)
    Spree::Order.where(retailer_shopify_identifier: value)
  end

  ## End Active Admin

  def self.batch_actions(action_name)
    actions = ['Archive Orders', 'Unarchive Orders', 'Pay for Orders']
    case action_name
    when 'archived'
      ['Unarchive Orders']
    else
      actions.reject { |a| a == 'Unarchive Orders' }
    end
  end
  # after_create :update_number

  def set_searchable_attributes
    other_attributes = { number: number, total: grand_total.to_s }

    self.searchable_attributes = other_attributes.merge(searchable_shopify_attributes).
                                 merge(searchable_address_attributes).
                                 merge(searchable_product_attributes).
                                 merge(searchable_variant_attributes).
                                 merge(searchable_customer_attributes)

    self.save!
  end

  def searchable_product_attributes
    {
      products: searchable_product_names,
      product_descriptions: searchable_product_descriptions
    }
  end

  def searchable_variant_attributes
    {
      variant_supplier_skus: searchable_variant_supplier_skus
    }
  end

  def searchable_shopify_attributes
    {
      retailer_shopify_identifier: retailer_shopify_identifier,
      retailer_shopify_order_number: retailer_shopify_order_number,
      retailer_shopify_name: retailer_shopify_name,
      retailer_shopify_number: retailer_shopify_number,
      supplier_shopify_identifier: supplier_shopify_identifier,
      supplier_shopify_order_name: supplier_shopify_order_name,
      supplier_shopify_number: supplier_shopify_number,
      supplier_shopify_order_number: supplier_shopify_order_number
    }
  end

  def searchable_address_attributes
    {
      shipping_address_address1: shipping_address&.address1,
      shipping_address_address2: shipping_address&.address2,
      shipping_address_city: shipping_address&.city,
      shipping_address_zipcode: shipping_address&.zipcode,
      shipping_address_phone: shipping_address&.phone,
      shipping_address_state: shipping_address&.name_of_state,
      shipping_address_country:  shipping_address&.country&.name,
      billing_address_address1:  billing_address&.address1,
      billing_address_address2: billing_address&.address2,
      billing_address_city: billing_address&.city,
      billing_address_zipcode: billing_address&.zipcode,
      billing_address_phone: billing_address&.phone,
      billing_address_state: billing_address&.name_of_state,
      billing_address_country: billing_address&.country&.name
    }
  end

  def searchable_customer_attributes
    {
      customer_email: customer_email,
      shipping_firstname: shipping_address&.firstname,
      shipping_lastname: shipping_address&.lastname,
      billing_firstname: billing_address&.firstname,
      billing_lastname: billing_address&.lastname,
      shipping_fullname: "#{shipping_address&.firstname} #{shipping_address&.lastname}",
      billing_fullname: "#{billing_address&.firstname} #{billing_address&.lastname}"
    }
  end

  def searchable_product_names
    line_items.map { |l| l.product.name }
  end

  def searchable_variant_supplier_skus
    line_items.map { |l| l.variant.platform_supplier_sku }
  end

  def searchable_product_descriptions
    line_items.map { |l| l.product.description }
  end

  def us_order?
    address = self.ship_address
    return if address.nil?

    country_us = Spree::Country.find_by(iso: 'US')
    (address.country_id == country_us.id) || compare_country_by_iso(country_us, address)
  end

  def canada_order?
    address = self.ship_address
    return if address.nil?

    country_us = Spree::Country.find_by(iso: 'CA')
    (address.country_id == country_us.id) || compare_country_by_iso(country_us, address)
  end

  def safe_to_modify?
    return false if
        self.paid? || self.payments.count.positive? ||
        self.successfully_sent_order? ||
        self.in_remittance_process?

    true
  end

  def has_payments_or_is_paid?
    self.paid? || self.payments.count.positive?
  end

  def make_payment(charge, card)
    payment_method = Spree::PaymentMethod.where(name: 'Custom Stripe').first_or_create!
    payment = self.payments.create(
      amount: charge.amount / 100.00,
      order_id: self.id,
      payment_method: payment_method,
      source: card,
      number: charge.id
    )

    if charge.paid && charge.captured
      payment.complete!
    else
      payment.failed!
    end
    payment
  end

  # def debug
  #   puts "Shipment Total: #{self.shipment_total.to_f}".blue
  #   puts "Item Total: #{self.item_total.to_f}".blue
  #   puts "Total: #{self.total.to_f}".blue
  # end

  def set_dropshipping_totals!
    self.shipments.each(&:update_amounts)
    self.update_totals
    self.save!
  end

  def remove_shipping!
    self.shipments.each(&:remove_shipping_cost!)
  end

  def set_line_item_costs!(cost)
    self.eligible_line_items.each do |line_item|
      line_item.set_cost_price!(cost)
    end
  end

  # Our policy right now is to only consider Paid / Not Paid.
  # We do not leverage Spree's states for payments
  def payment_state_display
    return 'Not Paid' unless self.payments.present?

    'Paid'
  end

  def paid?
    self.payments.present?
  end

  # def update_number
  #   self.number = "MXED-#{number}-#{internal_identifier.last(6).upcase}"
  #   self.save!
  # end

  def fulfillment_state_display
    return 'Pending' unless self.shipments.present?

    shipping_status = case shipment_state
                      when 'pending', 'ready'
                        'Unfulfilled'
                      when 'shipped'
                        'Fulfilled'
                      else
                        'N/A'
                      end
    shipping_status
  end

  def create_invoice
    invoice = self.order_invoices.new(
      number: (1000..3000).to_a.sample,
      amount: self.total,
      status: 'paid',
      retailer_id: self.retailer.id
    )
    invoice.save!
  end

  def update_payment_state!
    self.reload # Done to ensure all related items are freshest versions
    self.updater.update_payment_state
    self.save!
  end

  def set_shopify_store
    url = 'https://74cf1f50e403ffe04526fdcfa152f6bb:93af6550c01fc9c1a574bcd868309924'\
    '@test-supplier.myshopify.com/admin'
    ShopifyAPI::Base.site = url
  end

  def create_shopify_line_items
    all_shopify_line_items = []
    self.eligible_line_items.each do |line_item|
      all_shopify_line_items << ShopifyAPI::LineItem.new(
        quantity: line_item.quantity,
        variant_id: line_item.supplier_shopify_identifier,
        price: line_item.cost_price.to_s
      )
    end
    all_shopify_line_items
  end

  def create_shopify_shipping_line_items
    shipping_line_items = []
    self.eligible_line_items.each do |line_item|
      shipping_line_items << ShopifyAPI::ShippingLine.new(
        code: 'Shipping',
        price: 0,
        source: 'Hingeto',
        title: 'Shipping',
        variant_id: line_item.supplier_shopify_identifier
      )
    end
    shipping_line_items
  end

  # Used For Sending All Orders
  # TODO: Remove this
  def send_order_to_ghost
    set_shopify_store

    # Line Items
    all_shopify_line_items = create_shopify_line_items
    shipping_line_items = create_shopify_shipping_line_items

    # Shipping Line Items

    shipping_address = self.shipping_address
    customer_name = self.name
    first_name = customer_name.split(' ')[0]
    last_name = customer_name.split(' ')[1]

    shopify_order = ShopifyAPI::Order.new(
      line_items: all_shopify_line_items,
      customer: {
          first_name: first_name,
          last_name: last_name,
          email: self.email
      },
      shipping_address: {
          first_name: first_name,
          last_name: last_name,
          address1: shipping_address.address1,
          address2: shipping_address.address2,
          city: shipping_address.city,
          province: 'CA', # Needs to change
          phone: 'N/A',
          country: 'US',
          zip: shipping_address.zipcode
      },
      shipping_lines: shipping_line_items,
      note: 'N/A',
      source_name: 'hingeto',
      tags: 'hingeto'
    )
    shopify_order.save
    puts shopify_order.inspect
  end

  def self.search(keyword, retailer_id)
    puts "looking for orders for #{keyword}".blue

    orders = Spree::Order.where(retailer_id: retailer_id)

    puts "num orders #{orders.count}".blue

    return orders if keyword.to_s.empty?

    order_array = %i(number retailer_shopify_name
                     retailer_shopify_number supplier_shopify_identifier)

    Spree::Search.new(keyword: keyword, relation: orders,
                      custom_joins: {
                          t1: {
                              table_name: :spree_addresses,
                              foreign_key: :bill_address_id,
                              fields: %i(firstname lastname)
                          },
                          t2: {
                              table_name: :spree_addresses,
                              foreign_key: :ship_address_id,
                              fields: %i(firstname lastname)
                          }
                      },
                      joins: { variants: %i(sku supplier_sku),
                               products: [:description],
                               orders: order_array }).like
  end

  def has_inventory_available_for_line_items?
    self.eligible_line_items.each do |line_item|
      variant = line_item.variant
      return false if variant.nil?

      product = variant.product
      return false if product.nil?

      # Conditions that fail inventory
      return false unless variant.available_quantity.positive?
      return false unless product.discontinue_on.nil?
    end
    true
  end

  def total_cost_price_with_shipping
    self.eligible_line_items.sum(&:line_item_cost_with_shipping) + processing_fee
  end

  def total_cost_price_without_shipping
    self.eligible_line_items.sum(&:line_item_cost_without_shipping)
  end

  def total_shipping
    self.shipments.sum(&:per_item_cost)
  end

  def processing_fee
    (self.eligible_line_items.sum(&:line_item_cost_with_shipping)*0.029) + 0.3
  end

  def grand_total
    self.eligible_line_items.sum(&:line_item_cost)
  end

  def total_discount
    supplier_discount + hingeto_discount
  end

  def price_after_discount
    grand_total - total_discount
  end

  def apply_credit_discount!
    apply_supplier_discount! if retailer_credit.try(:has_supplier_credit?)
    apply_hingeto_discount! if retailer_credit.try(:has_hingeto_credit?)

    ActiveRecord::Base.transaction do
      retailer_credit.save if retailer_credit.present?
      self.save
    end
  end

  def apply_supplier_discount!
    return unless price_after_discount.positive?

    discount = retailer_credit.by_supplier
    applicable_discount = [price_after_discount, discount].min
    self.supplier_discount = applicable_discount
    retailer_credit.by_supplier = retailer_credit.by_supplier - applicable_discount
  end

  def apply_hingeto_discount!
    return unless price_after_discount.positive?

    discount = retailer_credit.by_hingeto
    applicable_discount = [price_after_discount, discount].min
    self.hingeto_discount = applicable_discount
    retailer_credit.by_hingeto = retailer_credit.by_hingeto - applicable_discount
  end

  def reset_order_for_retransmission!
    self.state = 'cart'
    self.shopify_logs = nil
    self.schedule_remittance
    self.supplier_shopify_identifier = nil
    self.save!
  end

  def in_remittance_process?
    self.scheduled? ||
      self.quantity_check? ||
      self.payment_remittance? ||
      self.order_remittance?
  end

  def awaiting_fulfillment?
    self.paid? && !self.shipped?
  end

  def paid_and_fulfilled?
    self.paid? && self.shipped?
  end

  def update_shopify_logs(log)
    current_log = self.shopify_logs
    current_log = '' if current_log.nil?
    current_log << "#{DateTime.now}: #{log}\n"
    self.update_column(:shopify_logs, current_log)
  end

  def fix_orders!
    self.eligible_line_items.each do |line_item|
      line_item.price = line_item.cost_price
      line_item.save
    end
    self.set_dropshipping_totals!
    self.update_payment_state!
  end

  def retailer_email
    return 'retailer@hingeto.com' if self.retailer_id.nil?

    retailer = self.retailer
    return retailer.email if retailer.email.present?
    return 'retailer@hingeto.com' if retailer.email.nil?
  end

  def retailer_name
    self.retailer&.name&.to_s
  end

  def supplier_name
    self.supplier&.name&.to_s
  end

  def set_shipments_per_item_costs!
    self.shipments.each do |shipment|
      shipment.per_item_cost = shipment.cost
      shipment.save!
    end
  end

  def find_most_expensive_shipment
    most_expensive = nil
    line_item_of_interest = nil

    self.eligible_line_items.each do |line_item|
      variant = line_item.variant
      product = variant.product

      shipping_category = product.shipping_category
      if shipping_category.present? && !shipping_category.shipping_methods.empty?
        calculator = shipping_category.shipping_methods[0].calculator

        if self.us_order?
          base_cost = calculator.preferences[:first_item_us]
          base_cost = set_to_non_zero(base_cost, 5)
        elsif self.canada_order?
          base_cost = calculator.preferences[:first_item_canada]
          base_cost = set_to_non_zero(base_cost, 8)
        else
          base_cost = calculator.preferences[:first_item_rest_of_world]
          base_cost = set_to_non_zero(base_cost, 10)
        end

        if most_expensive.nil? || most_expensive < base_cost
          most_expensive = base_cost
          line_item_of_interest = line_item
        end
      end
    end

    [most_expensive, line_item_of_interest]
  end

  def set_to_non_zero(val, default = 5)
    val || default
  end

  # Only call this method after you've created proposed shipments
  def find_and_set_most_expensive_shipment!
    set_shipments_per_item_costs!

    result = find_most_expensive_shipment
    most_expensive = result[0]
    line_item_of_interest = result[1]

    if most_expensive.nil?
      most_expensive = 5
      line_item_of_interest = self.eligible_line_items.first
    end

    # For canceled orders, there may not be any
    return if line_item_of_interest.nil?

    first_shipment = line_item_of_interest.inventory_units.first.shipment
    # first_shipment.update(cost: cheapest)
    # puts "first_shipment #{first_shipment}..".yellow
    # puts "first_shipment #{first_shipment.id}..".yellow
    # puts "Updating cost to #{most_expensive}..".yellow
    first_shipment.update(per_item_cost: most_expensive)
    first_shipment.save!

    set_total_shipment_on_order!
  end

  def mark_shipments_as_cancelled!; end

  def set_total_shipment_on_order
    self.reload
    self.total_shipment_cost = self.shipments.sum(&:per_item_cost).to_f
  end

  def set_total_shipment_on_order!
    self.set_total_shipment_on_order
    self.save!
  end

  def self.simulate_order_webhook!
    @variant_listing = Spree::VariantListing.first

    @data = File.open(File.join(Rails.root, 'test/fixtures/shopify/order.json')).read
    shopify_order = JSON.parse(@data, object_class: OpenStruct).order

    @team = Spree::Retailer.last

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'orders_import',
      initiated_by: 'system',
      retailer_id: @team.id,
      teamable_type: 'Spree::Retailer',
      teamable_id: @team.id,
      option_1: 'webhook',
      option_4: shopify_order.id,
      input_data: @data
    )
    ShopifyOrderImportJob.perform_now(job.internal_identifier)
  end

  def tracking_numbers
    tracking = []
    shipments.each do |shipment|
      next if shipment.tracking.nil?

      tracking << shipment.tracking unless
          tracking.include?(shipment.tracking)
    end
    tracking.join(', ')
  end

  def archived?
    archived_at.present?
  end

  def self.sample_orders_for_this_month
    # sample_orders.this_month
    sample_orders_with_free_shipping.completed_this_month
  end

  def self.sample_order_number
    number_generator.new_candidate(10)
  end

  def orderable?
    eligible_for_ordering_based_on_country? &&
      !in_remittance_process? && !error? && !successfully_sent_order? &&
      has_inventory_available_for_line_items?
  end

  # TODO: Need to change this post-Shopify feature launch.
  def eligible_for_ordering_based_on_country?
    return false if supplier.cannot_ship_internationally? && !us_order?

    true
  end

  # Returns hash of the line items with invalid variants
  # and the counter part to replace it with
  def get_discontinued_variants_and_valid_counterparts
    discontinued_variants = {}
    self.eligible_line_items.each do |line_item|
      variant = line_item.variant
      next unless variant.discontinued?
      # TODO: We may not necessarily want to skip these but doing so for now.
      next if variant.platform_supplier_sku.blank?

      active_variant = variant.return_non_discontinued_counterpart
      next if active_variant.nil?

      discontinued_variants[line_item.id] = active_variant
    end
    discontinued_variants
  end

  def replace_discontinued_variants_with_valid_counterpart!
    raise 'Cannot modify this order. It has already been sent' if
        self.successfully_sent_order?

    discontinued_line_items = self.get_discontinued_variants_and_valid_counterparts
    discontinued_line_items.each_key do |key|
      original_line_item = Spree::LineItem.find(key)
      new_line_item = original_line_item.dup
      new_line_item.variant_id = discontinued_line_items[key].id # Replace the variant
      new_line_item.save
      original_line_item.destroy
    end

    self.post_process_order!
  end

  def find_related_jobs_and_consolidate_reporting
    # job = Spree::LongRunningJob.where(option_1: self.internal_identifier)
  end

  def post_process_order!
    Rails.application.config.spree.stock_splitters =
      [Spree::Stock::Splitter::CustomSplitter]
    self.create_proposed_shipments
    self.reload
    self.set_dropshipping_totals!
    self.reload
    self.find_and_set_most_expensive_shipment!
    self.reload
    self.cancel_shipments_for_cancelled_line_items!
    self.set_searchable_attributes
  end

  def risk_severity_class(rec = nil)
    {
      'cancel' => 'tag-danger red',
      'investigate' => 'tag-warning warning',
      'accept' => 'tag-success green'
    }[rec || risk_recommendation]
  end

  def redownload_order_risks(initiating_user = nil)
    self.class.create_and_start_risks_import_job(id.to_s, initiating_user)
  end

  def self.redownload_all_order_risks(initiating_user = nil)
    create_and_start_risks_import_job(ids.join(','), initiating_user)
  end

  def self.create_and_start_risks_import_job(order_ids, initiating_user)
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'order_risks_import',
      initiated_by: 'user',
      user: initiating_user,
      option_4: order_ids
    )

    Shopify::OrderRisksImportJob.perform_later(job.internal_identifier)
  end

  def risky?
    risk_recommendation == 'cancel' || risk_recommendation == 'investigate'
  end

  def attempt_start_auto_payment!
    return if risky?
    return unless retailer.order_auto_payment && retailer.stripe_cards.present?
    return if grand_total > 100.00

    ActiveRecord::Base.transaction do
      job = create_auto_payment_job
      after_commit do
        Shopify::OrderExportJob.perform_later(job.internal_identifier)
      end
    end
  end

  def create_auto_payment_job
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'orders_export',
      initiated_by: 'system',
      option_1: internal_identifier.to_s,
      option_2: retailer.stripe_customer.default_card.internal_identifier,
      option_3: '1',
      setting_auto_paid: true,
      retailer_id: retailer.id,
      supplier_id: nil,
      teamable_type: nil,
      teamable_id: nil
    )
    job
  end

  def mark_as_sent_via_edi!
    self.sent_via_edi_at = DateTime.now
    self.save!
  end

  def mark_as_sent_via_sftp!
    self.sent_via_sftp_at = DateTime.now
    self.save!
  end

  def date_order_originally_placed
    original_order_date || created_at
  end

  def passed_fulfillment_date?
    DateTime.now > (must_fulfill_by || DateTime.now)
  end

  def days_to_ship
    # 3 all orders are required to be shipped in 3 business days
    # -1 multiply  with the date differnce to show lateness
    return 'N/A' if must_fulfill_by.nil? || !paid?
    return shipment_state if shipped? || cancelled?

    fulfillment_date = must_fulfill_by.to_date
    return fulfillment_date.business_days_until(DateTime.now) * -1 if passed_fulfillment_date?

    days = DateTime.now.business_days_until fulfillment_date
    days > 3 ? (days - 3) * -1 : days
  end

  def requested_shipping_service_code
    requested_shipping_method_id = self.requested_shipping_method_id ||
                                   self.retailer&.default_shipping_method_id
    return if requested_shipping_method_id.nil?

    requested_shipping_method =
      Spree::ShippingMethod.find(requested_shipping_method_id)
    requested_shipping_method&.service_code
  end

  def requested_shipping_service_code_mapped_to_supplier
    requested_shipping_method_id = self.requested_shipping_method_id ||
                                   self.retailer_default_shipping_method_id
    return if requested_shipping_method_id.nil?

    requested_shipping_method =
      Spree::ShippingMethod.find(requested_shipping_method_id)
    requested_shipping_method&.mapped_value_for_team(self.supplier)
  end

  # This should only be called when not considering using requested_shipping_method_id
  def retailer_default_shipping_method_id
    if us_order?
      retailer&.default_us_shipping_method_id
    elsif canada_order?
      retailer&.default_canada_shipping_method_id
    else
      retailer&.default_rest_of_world_shipping_method_id
    end
  end

  def requested_shipping_method_name
    requested_shipping_method_id = self.requested_shipping_method_id
    return if requested_shipping_method_id.nil?

    requested_shipping_method =
      Spree::ShippingMethod.find(requested_shipping_method_id)
    requested_shipping_method&.name
  end

  def line_item_total
    total = line_items.sum(&:line_item_cost)
    total
  end

  def quantity_total
    total = line_items.sum(&:quantity)
    total
  end

  def payment_sources
    if payments.any? && payments.pluck(:number).grep(/payment-waived-*/).any?
      'Credit Card, Store Credit'
    else
      'Credit Card'
    end
  end

  def shopify_order?
    supplier_platform == 'shopify'
  end

  def dsco_order?
    supplier_platform == 'dsco'
  end

  def edi_order?
    supplier_platform == 'edi'
  end

  def set_compliance_dates(adjustment_date = nil)
    adjustment_date ||= shipped? ? created_at : updated_at
    adjustment_date = adjustment_date.in_time_zone
    self.must_acknowledge_by = 12.business_hours.after adjustment_date
    self.must_fulfill_by = 3.business_days.after adjustment_date
    self.must_cancel_by = 1.business_day.after adjustment_date
    self.will_incur_penalty_at = 3.business_days.after adjustment_date
    self.save!
  end

  def generate_internal_storefront_line_item_identifiers!
    self.line_items.each do |line_item|
      line_item.update_columns(line_item_number: line_item.generate_line_item_number.to_s) unless
          line_item.line_item_number.present?
    end
  end

  def self.locate_orders_not_yet_sent_via_edi(since = nil)
    since ||= DateTime.now - 2.years
    supplier_ids = Spree::Supplier.all_remit_orders_via_suppliers.pluck(:id)
    return [] if supplier_ids.empty?

    orders = Spree::Order.from_created(since).where(supplier_id: supplier_ids,
                                                    shipment_state: 'ready',
                                                    sent_via_edi_at: nil)
    orders
  end

  # Methods to unify information irregardless of the partner
  def sent_to_supplier_at
    case supplier_platform
    when 'dsco'
      self.shopify_sent_at
    when 'edi'
      self.sent_via_edi_at
    when 'shopify'
      self.shopify_sent_at
    when 'sftp'
      self.sent_via_sftp_at
    else
      'N/A'
    end
  end

  def supplier_order_number
    case supplier_platform
    when 'dsco'
      self.number
    when 'shopify'
      self.supplier_shopify_order_name
    when 'edi'
      self.purchase_order_number
    else
      'N/A'
    end
  end

  def cancel_entire_order!
    ActiveRecord::Base.transaction do
      self.shipment_state = 'canceled'
      self.canceled_at ||= DateTime.now
      save!
      line_items.each(&:mark_as_canceled!)
    end
  rescue => ex
    puts "Issue: #{ex}".red
    puts "Issue: #{ex.backtrace}".red
  end

  def completed_stripe_payments
    payments.select { |p| p.source_type == 'StripeCard' && p.state == 'completed' }
  end

  def eligible_stripe_payments
    payments.select do |p|
      p.source_type == 'StripeCard' &&
        (p.state == 'completed' || p.state == 'partially_refunded')
    end
  end

  def shipped?
    shipment_state == 'shipped'
  end

  def cancelled?
    shipment_state == 'canceled'
  end

  def valid_line_items
    line_items.reject(&:cancelled?)
  end

  def retailer_gets_first_sale
    order_count = Spree::Order.where('spree_orders.retailer_id = ?', self.retailer_id).count
    if order_count == 1
      ::Retailer::RetailerGetsFirstSaleJob.perform_later(self.retailer_id)
    end
  end

  private

  def compare_country_by_iso(country_us, address)
    return false if address.nil? || country_us.nil?

    address.country.iso == country_us.iso
  end
end
