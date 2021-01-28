# The purpose of this model is to serve as a global index
# of all Product in Retailer/Supplier stores
class ShopifyCache::Order
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  validates_presence_of :shopify_url
  validates_presence_of :role

  embeds_many :line_items, class_name: 'ShopifyCache::LineItem', inverse_of: :order do
    def find_line_item_by_sku(sku)
      where(sku: /^#{::Regexp.escape(sku)}$/i).first
    end

    def quantity_in_cart(sku)
      where(sku: /^#{::Regexp.escape(sku)}$/i).sum(:quantity)
    end
  end

  # This does not represent the complete list.
  field :email, type: String
  field :closed_at, type: String
  field :created_at, type: String
  field :processed_at, type: String
  field :number, type: Integer
  field :note, type: String
  field :token, type: String
  field :confirmed, type: Boolean
  field :updated_at, type: String
  field :tags, type: String
  field :admin_graphql_api_id, type: String
  field :published_scope, type: String
  field :total_price, type: String
  field :subtotal_price, type: String
  field :financial_status, type: String
  field :fulfillment_status, type: String
  # Hingeto fields
  field :role, type: String
  field :shopify_url, type: String
  field :num_line_items, type: Integer

  # Indices
  index({ handle: 1 }, background: true)
  index({ shopify_url: 1, role: 1 }, background: true)
  index({ num_line_items: 1 }, background: true)
  index({ 'line_items.sku': 1 }, background: true)
  index({ fulfillment_status: 1 }, background: true)
  index({ shopify_url: 1, role: 1, fulfillment_status: 1, 'line_items.sku': 1 }, background: true)

  # Billing Address
  index({ 'billing_address.name': 1 }, background: true)
  index({ 'billing_address.address1': 1 }, background: true)

  # Shipping Address
  index({ 'shipping_address.name': 1 }, background: true)
  index({ 'shipping_address.address1': 1 }, background: true)

  def self.locate_possible_matches_at_supplier(local_order)
    ship_address = local_order&.ship_address
    return [] if ship_address.nil?

    supplier = local_order.supplier
    results = where(
      'shopify_url' => supplier.shopify_url,
      'role' => 'supplier',
      'shipping_address.address1' => ship_address.address1,
      'shipping_address.name' => ship_address.full_name
    ).all
    results
  end

  # Number of orders that have this SKU in their cart.
  # Note - this does not factor in line items having multiple quantities
  # In future - we'll want to consider time limiting how far we go back with orders
  def self.unfulfilled_orders_at_retailer_store(platform_supplier_sku:, retailer:)
    return [] if platform_supplier_sku.nil?
    return [] if retailer.nil?

    search_hash =
      {
          'shopify_url' => retailer.shopify_url,
          'role' => 'retailer',
          :fulfillment_status.nin => ['fulfilled'],
          'line_items.sku' => /^#{::Regexp.escape(platform_supplier_sku)}$/i
      }
    results = where(search_hash).order('created_at desc')
    results
  end

  def self.num_unfulfilled_orders_at_retailer_store(platform_supplier_sku:, retailer:)
    return 0 if retailer.nil? || platform_supplier_sku.nil?

    unfulfilled_orders_at_retailer_store(
      platform_supplier_sku: platform_supplier_sku,
      retailer: retailer
    ).count
  end

  def self.quantity_of_items_in_orders_at_retailer_store(platform_supplier_sku:, retailer:)
    return 0 if retailer.nil? || platform_supplier_sku.nil?

    # Find all orders
    orders = unfulfilled_orders_at_retailer_store(
      platform_supplier_sku: platform_supplier_sku,
      retailer: retailer
    )

    # Now iterate & sum all the quantities
    sum = 0
    orders.each do |o|
      sum += o.line_items.quantity_in_cart(platform_supplier_sku)
    end
    sum
  end

  def self.find_shopify_supplier_order(supplier_shopify_identifier:, supplier:)
    return nil if supplier_shopify_identifier.nil?
    return nil if supplier.nil?

    search_hash =
      {
          'shopify_url' => supplier.shopify_url,
          'role' => 'supplier',
          'id' => supplier_shopify_identifier.to_i
      }
    find_by(search_hash)
  end

  def self.locate_orders_at_supplier_store(platform_supplier_sku:, supplier:)
    return [] if platform_supplier_sku.nil?
    return [] if supplier.nil?

    search_hash =
      {
          'shopify_url' => supplier.shopify_url,
          'role' => 'supplier',
          'line_items.sku' => /^#{::Regexp.escape(platform_supplier_sku)}$/i
      }
    results = where(search_hash).order('created_at desc')
    results
  end
end
