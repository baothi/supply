Spree::LineItem.class_eval do
  include InternalIdentifiable
  include Spree::LineItems::Dscoable
  include Spree::LineItems::Refundable
  include CommitWrap

  delegate :original_supplier_sku, to: :variant
  delegate :name, to: :retailer, prefix: true, allow_nil: true
  delegate :number, :retailer_shopify_number, :retailer_shopify_name,
           :fulfillment_state_display, :completed_at,
           :payment_state_display, :payment_sources, :risk_recommendation,
           :supplier_shopify_order_name,
           to: :order, prefix: true, allow_nil: true
  delegate :msrp_price, :platform_supplier_sku, :original_supplier_sku,
           to: :variant, prefix: true, allow_nil: true
  delegate :name, :price, to: :product, prefix: true, allow_nil: true
  delegate :name, to: :supplier, prefix: true, allow_nil: true
  delegate :name, to: :retailer, prefix: true, allow_nil: true

  alias_method :product_title, :product_name

  delegate :name, to: :retailer, prefix: true, allow_nil: true

  delegate :name, :number, :retailer_shopify_number, :retailer_shopify_name,
           :fulfillment_state_display, :tracking_numbers, :completed_at,
           :payment_state_display, :payment_sources, :risk_recommendation,
           to: :order, prefix: true, allow_nil: true

  delegate :msrp_price, to: :variant, prefix: true, allow_nil: true

  delegate :name, :price, to: :product, prefix: true, allow_nil: true

  delegate :name, to: :supplier, prefix: true, allow_nil: true
  delegate :name, to: :retailer, prefix: true, allow_nil: true

  belongs_to :retailer
  belongs_to :supplier

  def wholesale_cost
    self.cost_from_master
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i(retailer_id_eq supplier_id_eq order_id_eq order_number_equals)
  end

  def self.retailer_id_eq(retailer_id)
    self.where(retailer_id: retailer_id)
  end

  def self.order_number_equals(number)
    Spree::Order.where('retailer_shopify_name iLIKE ?', "#{number}%").
      or(Spree::Order.where('number iLIKE ?', "#{number}%")).
      try(:first).try(:line_items)
  end

  def ship_date
    return order.shipments.first.try(:fulfilled_at) if shipped?

    'Not Yet Shipped'
  end

  # This was introduced on 4/30 to address a broken ship date issue
  def broken_ship_date
    return order.shipments.first.try(:invalid_fulfilled_at) if shipped?

    'Not Yet Shipped'
  end

  def terms
    'Commission'
  end

  def shipping_country
    order.shipping_address&.country&.name
  end

  def mark_fulfillment_time!(fulfilled_at, forced = false)
    return if self.fulfilled_at.present? && !forced

    self.update(fulfilled_at: fulfilled_at)
  end

  def mark_fulfillment_time_to_now!(forced = false)
    mark_fulfillment_time!(DateTime.now, forced)
  end

  def fulfill_shipment(tracking_number, fulfilled_at = nil)
    # We don't want to mess with fully shipped or fully cancelled orders
    return if self.order_already_shipped_or_cancelled?

    fulfilled_at ||= DateTime.now
    inventory_units = self.inventory_units
    inventory_units.each do |inventory_unit|
      shipment = inventory_unit.shipment
      # Only set if it wasn't previously set
      next if shipment.shipped_or_cancelled?

      shipment.state = 'shipped'

      shipment.tracking ||= tracking_number
      shipment.fulfilled_at ||= fulfilled_at
      shipment.save!

    end
    order = self.order
    order.shipment_state = order.updater.update_shipment_state
    order.save!
    # move order updating out here?
    self.mark_fulfillment_time!(fulfilled_at)
  end

  def shipped?
    inventory_units = self.inventory_units
    status = true
    inventory_units.each do |inventory_unit|
      status = false if inventory_unit.shipment.state != 'shipped'
    end
    status
  end

  def cancelled?
    inventory_unit = self.inventory_units[0]
    # return false if inventory_unit.nil?
    shipment = inventory_unit.shipment
    shipment.state == 'canceled'
  end

  def mark_as_canceled!
    return if self.order.shipment_state == 'shipped'

    begin
      self.cancelled_at ||= DateTime.now
      self.save!
      self.cancel_line_item_shipments!
      self.order.update_shopify_logs("Cancelled line item: #{self.variant.platform_supplier_sku}")
    rescue => e
      puts "Issue: #{e}".red
      puts "Issue mark_as_canceled!!: #{e.backtrace}".red
      Rollbar.error(e)
    end
  end

  # Marks all shipments
  def cancel_line_item_shipments!
    return if self.order.shipment_state == 'shipped'

    begin
      self.inventory_units.each do |inventory_unit|
        shipment = inventory_unit.shipment
        inventory_unit.mark_as_cancelled! unless inventory_unit.shipped?
        shipment.mark_as_cancelled! unless shipment.shipped?
      end
    rescue => e
      puts "Issue: #{e}".red
      puts "Issue cancel_line_item_shipments!: #{e.backtrace}".red
      Rollbar.error(e)
    end
  end

  def shipment_state
    inventory_units = self.inventory_units
    num_shipped = 0
    num_shipments = inventory_units.count
    inventory_units.each do |inventory_unit|
      num_shipped += 1 if inventory_unit.shipment.state == 'shipped'
    end

    return 'canceled' if cancelled?
    return 'pending' if num_shipped.zero?
    return 'shipped' if num_shipments == num_shipped
    return 'partial' if num_shipped >= 1
  end

  def shipments
    inventory_units = self.inventory_units
    inventory_units.map(&:shipment)
  end

  def tracking_numbers
    shipments.map(&:tracking).compact.join(';')
  end

  def line_item_cost_with_shipping
    (cost_from_master * self.quantity) + self.line_item_shipping_cost
  end

  def line_item_cost_without_shipping
    cost_from_master * self.quantity
  end

  def line_item_cost
    (cost_from_master * self.quantity) + self.line_item_shipping_cost
  end

  # TODO: Contemplate falling back to variant.cost if master_cost is not available
  def cost_from_master
    variant.master_cost || variant.cost_price
  end

  def line_item_shipping_cost
    @line_item_shipping_cost ||= begin
      sum = 0
      inventory_units = self.inventory_units
      inventory_units.each do |inventory_unit|
        shipment = inventory_unit.shipment
        sum += shipment.per_item_cost
      end
      sum
    end
  end

  def set_cost_price!(cost_price)
    self.cost_price = cost_price
    self.save!
  end

  def total_sales
    quantity * wholesale_cost
  end

  def hingeto_commission
    0.1 * total_sales
  end

  def supplier_payment_amount
    (total_sales + line_item_shipping_cost) - hingeto_commission
  end

  # For now, we'll generate the line item number based on when created
  def generate_line_item_number
    all_line_items = self.order.line_items.order('created_at asc').to_a
    (all_line_items.index(self) + 1).to_s.rjust(3, '0')
  end

  # Fulfillments

  def order_already_shipped_or_cancelled?
    self.order.shipment_state == 'shipped' || self.order.shipment_state == 'canceled'
  end

  def fulfill_line_item_shipments!(service_code, tracking_number)
    if order_already_shipped_or_cancelled?
      order_number = self.order.retailer_shopify_order_number
      OperationsMailer.generic_email_to_admin(
        "[Warning] Fulfillment received for already shipped/canceled order #{order_number}",
        "Someone sent tracking number: #{tracking_number} "\
      "for order: #{order_number}. This order was already "\
      "#{self.order.shipment_state}. Typically this means supplier shipped "\
      "an order that was supposed to be cancelled.\n\n"\
      'There is nothing to do as we have ignored this fulfillment request update but the ' \
      'retailer should be notified so that they can resolve with the supplier'
      ).deliver_later
      return
    end

    begin
      inventory_units = self.inventory_units
      inventory_units.each do |inventory_unit|
        shipment = inventory_unit.shipment
        # shipment.tracking = tracking_number
        shipment.tracking = tracking_number
        shipment.state = 'shipped'

        # Now add Shipping Method Info
        # puts "Looking for service code: #{service_code}".blue
        shipping_method = Spree::ShippingMethod.find_by_service_code!(service_code)

        shipment.shipping_method_id = shipping_method.id
        shipment.courier_id = shipping_method.courier_id
        shipment.fulfilled_at = DateTime.now

        shipment.save!
      end
    # current_order = self.order
    # current_order.updater.up
    #
    # # Generate XML
    # job = create_long_running_job
    # puts "Performing with: #{job.internal_identifier}"

    # current_order.save
    rescue => e
      # TODO: This should report to Rollbar
      puts "Issue fulfill_line_item_shipments!: #{e}".red
      puts "Issue fulfill_line_item_shipments!: #{e.backtrace}".red
    end
  end

  def self.download_finance_report(params, user_id)
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create!(
        action_type: 'export',
        job_type: 'csv_export',
        initiated_by: 'user',
        user_id: user_id,
        option_1: params[:q].try(:to_json) || '{}'
      )
      execute_after_commit do
        Csv::Export::FinanceReportWorker.perform_async(job.internal_identifier)
      end
    end
  end

  def fully_refunded?
    self.refunded_total_at.present?
  end
end
