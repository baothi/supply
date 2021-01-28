class ShopifyOrderDiagnosis
  def initialize(order, retailer)
    @shopify_order = order
    @retailer = retailer
    @report = { order: @shopify_order }
  end

  def perform
    begin
      return @report unless @shopify_order.present?

      @retailer.initialize_shopify_session!
      @line_items = Shopify::Import::FilterLineItem.new(
        order: @shopify_order,
        retailer: @retailer
      ).perform
      if @line_items.present?
        @report[:line_items] = @line_items
        validate_fulfillment
      end

      validate_payment
      validate_archived_state
      return @report unless @line_items.present?

      validate_mxed_product
      validate_stock
      validate_address
      @report
    rescue => e
      puts e.to_s.red
      nil
    end
  end

  def validate_payment
    @report[:paid_check] = @shopify_order.financial_status == 'paid'
  end

  def validate_fulfillment
    @report[:fulfilled] = true
    fulfillments = ShopifyAPI::Fulfillment.find(
      :all,
      params: { order_id: @shopify_order.id, status: 'success' }
    )
    return if fulfillments.empty?

    @report[:fulfilled_with_tracking] = []
    @report[:fulfilled_without_tracking] = []
    fulfillments.each do |f|
      fulfilled = f.line_items & @line_items
      next unless fulfilled.present?

      if f.tracking_number.present?
        @report[:fulfilled_with_tracking] << fulfilled
      else
        @report[:fulfilled_without_tracking] << fulfilled
      end
    end
    @report[:fulfilled] = @report[:fulfilled_with_tracking].blank? &&
                          @report[:fulfilled_without_tracking].blank?
  end

  def validate_archived_state
    @report[:archive_check] = @shopify_order.closed_at.blank?
  end

  def validate_mxed_product
    @report[:mxed_check] = @line_items.present?
  end

  def validate_address
    begin
      @report[:us_address] = false
      customer_default_address = @shopify_order.try(:customer).try(:default_address)
      shipping_address = @shopify_order.try(:shipping_address)
      address = shipping_address || customer_default_address
      @report[:address_check] = address.present?
      return unless @report[:address_check]

      @report[:us_address] = address.country_code == 'US'
    rescue
      false
    end
  end

  def validate_stock
    @report[:unmatched_line_items] = []
    @report[:available] = []
    @report[:unavailable] = []
    @report[:in_stock] = []
    @report[:out_of_stock] = []
    @line_items.each do |line_item|
      variant = VariantLineItemMatcher.new(line_item, @retailer).perform
      if variant.blank?
        @report[:unmatched_line_items] << line_item
        next
      end
      variant.available? ? @report[:available] << line_item : @report[:unavailable] << line_item
      if variant.count_on_hand > line_item.quantity
        @report[:in_stock] << line_item
      else
        @report[:out_of_stock] << line_item
      end
    end
    @report[:stock_check] = @report[:unavailable].empty? && @report[:out_of_stock].empty?
  end
end
