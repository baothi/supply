class SampleOrder
  attr_accessor :variant
  attr_accessor :retailer
  def initialize(retailer_id, supplier_id, variant_id, address)
    @supplier = Spree::Supplier.find_by(id: supplier_id)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @variant = Spree::Variant.find_by(internal_identifier: variant_id)
    @address = address
  end

  def perform
    create_order
  end

  def order_params
    {
        email: 'customer@hingeto.com',
        customer_email: retailer.email,
        shipping_address: shipping_address,
        billing_address: shipping_address,
        retailer_id: @retailer.id,
        supplier_id: @supplier.id,
        source: 'app'
    }
  end

  def shipping_address
    begin
      address = Spree::Address.new(address_params)
      address.save!
      address
    rescue => e
      puts e
      nil
    end
  end

  def address_params
    country = Spree::Country.find_by(iso: 'US')
    state = Spree::State.find_or_create_by(
      name: 'NOT_IN_USE',
      abbr: 'NOT_IN_USE',
      country: country
    )

    {
        firstname: @address[:first_name],
        lastname: @address[:last_name],
        address1: @address[:address1],
        address2: @address[:address2],
        city: @address[:city],
        zipcode: @address[:zipcode],
        phone: @address[:phone] || 'N/A',
        name_of_state: @address[:name_of_state],
        state_id: state.id,
        country_id: country.id
    }
  end

  def add_line_items(order)
    begin
      order.line_items.new(
        variant: variant,
        quantity: 1,
        price: variant.cost_price
      )
    rescue => e
      puts e
    end
  end

  def post_process_order!(order)
    begin
      order.state = 'complete'
      order.completed_at = Time.now
      order.shipment_state = 'pending'
      order.save!

      Rails.application.config.spree.stock_splitters =
        [Spree::Stock::Splitter::CustomSplitter]
      order.create_proposed_shipments

      # Set Costs etc.
      set_costs order unless retailer.eligible_for_sample_order_free_shipping?
      order.set_searchable_attributes
      order
    rescue => e
      puts e
    end
  end

  def create_order
    begin
      order = Spree::Order.new(order_params)

      raise 'Samples are not allowed for this product' unless
          @supplier.allow_free_shipping_for_samples?

      return unless valid_order? order

      order.total = variant.cost_price
      add_line_items(order)
      if order.line_items.present? && order.save!
        order = post_process_order!(order)
      end

      order if order.persisted?
    rescue => e
      puts "#{e}".red
      puts "#{e.backtrace}".red
    end
  end

  def valid_order?(order)
    # Ensure there's an address
    raise 'Cannot create sample without address.' if
        order.shipping_address.nil? || order.billing_address.nil?

    true
  end

  def set_costs(order)
    order.reload
    order.set_dropshipping_totals!
    order.reload
    order.find_and_set_most_expensive_shipment!
  end
end
