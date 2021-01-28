Spree::ShippingMethod.class_eval do
  belongs_to :courier,
             class_name: 'Spree::Courier'

  belongs_to :supplier,
             class_name: 'Spree::Supplier'

  has_many :mapped_shipping_methods,
           class_name: 'Spree::MappedShippingMethod'

  scope :active, -> { where(active: true) }

  CSV_MAPPING = {
    name: 'Shipping Method Name',
    first_item_us: 'US Base Price',
    additional_item_us: 'US Additional Price',
    first_item_canada: 'Canada Base Price',
    additional_item_canada: 'Canada Additional Price',
    first_item_rest_of_world: 'ROW Base Price',
    additional_item_rest_of_world: 'ROW Additional Price'
  }.freeze

  # CSV_IMPORT_MAPPING = {
  #   us_base_price: :first_item_us,
  #   us_additional_price: :additional_item_us,
  #   canada_base_price: :first_item_canada,
  #   canada_additional_price: :additional_item_canada,
  #   row_base_price:  :first_item_rest_of_world,
  #   row_additional_price: :additional_item_rest_of_world
  # }.freeze

  def supplier_name
    return '' unless supplier.present?

    supplier.name
  end

  def get_price(preference)
    calculator.get_preference(preference)
  end

  # This is used to collect the list of Real Shipping Methods
  # versus the ones used for calculating what to charge
  # retailers
  def self.real_shipping_methods
    Spree::ShippingMethod.where('service_code is not null')
  end

  # Returns mapped value for team. Otherwise, returns default
  def mapped_value_for_team(team)
    mapped_shipping_method = Spree::MappedShippingMethod.where(
      teamable: team,
      shipping_method_id: self.id
    ).first

    value = if mapped_shipping_method.nil?
              self.service_code
            else
              mapped_shipping_method.value
            end
    value
  end

  CSV_MAPPING.keys.each do |method|
    next if method == :name

    define_method method do
      calculator.get_preference(method)
    end
  end
end
