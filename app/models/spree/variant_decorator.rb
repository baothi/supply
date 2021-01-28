Spree::Variant.class_eval do
  # Internal Identifier
  include InternalIdentifiable

  # Inventory
  include Spree::Variants::SupplierInventory

  # Variant Marketplace Compliance
  include Spree::Variants::MarketplaceCompliance

  # Image Management
  include Spree::Listings::ImageHelpers

  # Search Scope
  include Spree::Variants::SearchScope
  include Spree::Variants::FilterScope
  include Spree::Calculator::PriceCalculator

  # Color Mapping
  include Spree::Variants::ColorOptionable
  include Spree::Variants::SizeOptionable

  has_many :variant_listings

  belongs_to :supplier, class_name: 'Spree::Supplier'

  attr_accessor :shopify_variants

  scope :price_managed_by_master_sheet, -> {
    where('spree_variants.price_management = :platform',
          platform: Spree::VariantCost::MASTER_SHEET)
  }

  scope :price_not_managed_by_master_sheet, -> {
    where('spree_variants.price_management != :platform',
          platform: Spree::VariantCost::MASTER_SHEET)
  }

  scope :price_managed_by_shopify, -> {
    where('spree_variants.price_management = :platform',
          platform: Spree::VariantCost::SHOPIFY)
  }

  scope :price_managed_by_upload, -> {
    where('spree_variants.price_management = :platform',
          platform: Spree::VariantCost::UPLOAD)
  }

  scope :marketplace_compliant, -> {
    where('spree_variants.marketplace_compliant = true')
  }

  scope :submission_compliant, -> {
    where('spree_variants.submission_compliant = true')
  }

  scope :not_submission_compliant, -> {
    where('spree_variants.submission_compliant != true')
  }

  scope :has_approved_product, -> {
    joins(:product).where(
      'spree_products.submission_state = :submission_state',
      submission_state: 'approved'
    )
  }

  scope :has_approved_product_but_not_submission_compliant, -> {
    has_approved_product.not_submission_compliant
  }

  scope :has_approved_product_but_not_managed_by_master_sheet, -> {
    has_approved_product.price_not_managed_by_master_sheet
  }

  scope :not_discontinued_and_submission_compliant, -> {
    not_discontinued.submission_compliant
  }

  scope :not_discontinued_and_not_submission_compliant, -> {
    not_discontinued.not_submission_compliant
  }

  SHOPIFY_SPREE_MAPPING = { cost_price: 'Wholesale Cost', platform_supplier_sku: 'Variant SKU',
                            variant_price: 'Variant Price',
                            compare_at: 'Variant Compare At Price' }.freeze

  WEIGHT_MAPPINGS = { 'lb' => 'POUNDS', 'kg' => 'KILOGRAMS', 'g' => 'GRAMS' }.freeze

  validates_uniqueness_of :gtin, allow_blank: true, allow_nil: true, scope: :supplier_id

  # enum price_management: { shopify: 'shopify', upload: 'upload' }

  before_save :update_platform_sku, if: :original_supplier_sku_changed?
  before_save :upcase_skus

  # Ensure costs are properly set. Try our best to ensure that this
  # is the last concern that contains a before_save to mitigate chances
  # of conflict
  include Spree::Variants::CostManageable

  def upcase_skus
    self.original_supplier_sku = self.original_supplier_sku&.upcase
    self.platform_supplier_sku = self.platform_supplier_sku&.upcase
  end

  # To be used for
  def return_non_discontinued_counterpart
    # raise 'This cannot be called for non-discontinued variants' unless discontinued?

    active_variant =
      Spree::Variant.
      where(product_id: self.product_id,
            platform_supplier_sku: self.platform_supplier_sku).
      where.not(id: self.id).last

    active_variant
  end

  def return_possible_counterparts
    Spree::Variant.where(
      platform_supplier_sku: self.platform_supplier_sku,
      discontinue_on: nil
    ).where.not(id: self.id)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w(sku product_id internal_identifier supplier_id) + _ransackers.keys
  end

  def self.compare_option(local_variant, shopify_variant, option_number)
    if option_number == 1
      option_value = local_variant.first_option_value
      shopify_value = shopify_variant.option1
    elsif option_number == 2
      option_value = local_variant.second_option_value
      shopify_value = shopify_variant.option2
    elsif option_number == 3
      option_value = local_variant.third_option_value
      shopify_value = shopify_variant.option3
    end

    return false unless option_value.present?

    puts "[#{option_number}] Comparing #{option_value.upcase} "\
        "with #{shopify_value.upcase}"
    option_value.casecmp(shopify_value).zero?
  end

  def self.find_local_variant(local_product, shopify_variant)
    local_variant = nil
    local_product.variants.each do |variant|
      option1 = true
      option2 = true
      option3 = true

      option1 = compare_option(variant, shopify_variant, 1) unless
          shopify_variant.option1.nil?
      option2 = compare_option(variant, shopify_variant, 2) unless
          shopify_variant.option2.nil?
      option3 = compare_option(variant, shopify_variant, 3) unless
          shopify_variant.option3.nil?

      if option1 && option2 && option3
        puts 'Found Match!'.green
        local_variant = variant
      end

      puts '---'.yellow
    end

    local_variant
  end

  def self.locate_hingeto_variant(platform_supplier_sku:)
    where(platform_supplier_sku: platform_supplier_sku).
      order('created_at desc').first
  end

  # We only use / assume one stock item per variant for the time being.
  def count_on_hand
    if self.stock_items.empty?
      0
    else
      self.stock_items.first.count_on_hand
    end
  end

  def retailer_listing(retailer_id)
    variant_listings.where(retailer_id: retailer_id).first
  end

  def exported?; end

  def commission_from_dropshipping
    return 0 if msrp_price.nil? || price.nil?

    msrp_price.to_f - price.to_f
  end

  def available_at_supplier_shopify?; end

  def update_inventory_from_shopify!
    begin
      stock_item = self.stock_items.first
      return if !stock_item.nil? && stock_item.updated_at >= DateTime.now - 15.minutes

      self.supplier.initiatialize_shopify_session
      supplier_shopify_identifier = self.shopify_identifier
      ShopifyAPIRetry.retry(5) do
        shopify_variant = ShopifyAPI::Variant.find(supplier_shopify_identifier)
        update_variant_stock(shopify_variant.inventory_quantity)
      end
    rescue => e
      puts "#{e}".red
    end
  end

  # This is the quantity, adjusted for supplier buffer and other factors
  def available_quantity(retailer: nil)
    return legacy_available_quantity if original_supplier_sku.blank?

    if supplier&.shopify_supplier?
      Spree::Variant.available_quantity_at_shopify(
        supplier: supplier,
        retailer: retailer,
        original_supplier_sku: original_supplier_sku,
        platform_supplier_sku: platform_supplier_sku
      )
    else
      legacy_available_quantity
    end
  end

  # Assumes xxx-xxx-YYYYY where YYYYY is the supplier brand short code
  # As syndicated to Retailer Stores
  def self.derive_sku_components(platform_supplier_sku:)
    sku_parts = platform_supplier_sku.split('-')

    brand_short_code = sku_parts.pop.strip
    # Rejoin with the remaining components post-pop
    original_supplier_sku = sku_parts.join('-')
    {
        brand_short_code: brand_short_code,
        original_supplier_sku: original_supplier_sku,
        platform_supplier_sku: platform_supplier_sku
    }
  end

  def legacy_available_quantity
    # return 0 if self.discontinued? # || !self.available?
    # return 0 if product.discontinued? # || !product.available?

    stock_item = self.stock_items.first
    return 0 if stock_item.nil?

    supplier_buffer = (self.supplier&.setting_inventory_buffer).to_i

    final_count = stock_item.count_on_hand - supplier_buffer
    return 0 if final_count <= 0

    final_count
  end

  # Remove locking code.
  def update_variant_stock(qty)
    variant_stock_item = stock_items.first_or_create! do |stock_item|
      stock_item.stock_location = Spree::StockLocation.first
    end
    variant_stock_item.update(count_on_hand: qty)
  end

  def sync_shopify_weight!(shopify_variant)
    self.weight = shopify_variant.weight
    self.weight_unit = shopify_variant.weight_unit
    self.save!
  end

  def presentation
    "#{first_option_value}, #{second_option_value}"
  end

  def full_presentation
    nil if self.is_master
    "#{self.product.name} - #{presentation}"
  end

  # TODO: Give retailers the ability to select the case they want options to go out as.
  # At the moment we are defaulting to uppercase for the options

  # Our rule of thumb is that first option is color & then size

  # Color - We use original supplier values if platform value is not available
  def first_option_value
    self.platform_color_option&.presentation ||
      self.supplier_color_option&.presentation ||
      self.supplier_color_value&.titleize&.upcase
  end

  # Size
  def second_option_value
    # We use original supplier because sizes can be funkier i.e. XL vs 34 vs OSFM
    self.platform_size_option&.presentation ||
      self.supplier_size_option&.presentation ||
      self.supplier_size_value&.titleize&.upcase
  end

  def create_variant_listing(shopify_variant_id, retailer_id, product_listing_id)
    variant_listing = self.retailer_listing(retailer_id)
    return if variant_listing.present?

    listing = Spree::VariantListing.unscoped.find_or_initialize_by(
      variant_id: self.id,
      retailer_id: retailer_id,
      supplier_id: self.supplier_id
    )

    listing.update(
      shopify_identifier: shopify_variant_id,
      deleted_at: nil,
      product_listing_id: product_listing_id
    )

    return listing if listing.save!
  end

  def shopify_params(retailer)
    service_id = Shopify::GraphAPI::Base.encode_id(
      ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME'], :FulfillmentService
    )
    {
        title: name,
        options: [first_option_value, second_option_value],
        sku: platform_supplier_sku,
        inventoryManagement: 'SHOPIFY',
        # This requires Hingeto to exist properly. The graphQL end point lets us
        # use either the proper ID or the friendly name (i.e. hingeto)
        fulfillmentServiceId: service_id,
        price: msrp_price,
        weight: weight.to_f,
        weightUnit: weight_unit_mappings,
        inventoryQuantities: get_inventory_levels(retailer),
        imageSrc: images.first&.attachment&.url(:original)
    }
  end

  # Default weight unit = POUNDS if not defined in spree_variants.weight_unit
  # Shopify only takes up weightUnit values: GRAMS, KILOGRAMS, OUNCES, POUNDS
  def weight_unit_mappings
    WEIGHT_MAPPINGS[weight_unit] || 'POUNDS'
  end

  def get_inventory_levels(retailer)
    inventory_levels = []
    location_id = Shopify::GraphAPI::Base.encode_id(
      retailer.default_location_shopify_identifier, :Location
    )
    inventory_levels << {
        locationId: location_id,
        availableQuantity: available_quantity(retailer: retailer)
    }
    inventory_levels
  end

  def generate_platform_sku
    brand_short_code = self.supplier&.brand_short_code
    raise 'Supplier Brand Code is not set' unless brand_short_code.present?
    return nil if self.original_supplier_sku.nil?

    "#{self.original_supplier_sku}-#{supplier.brand_short_code}"
  end

  def update_platform_sku
    self.platform_supplier_sku = self.generate_platform_sku
  end

  # TODO: Consider using unscoped here.. not using unscoped may have consequences
  def has_unique_supplier_sku?
    count = if new_record?
              Spree::Variant.where('original_supplier_sku = :original_supplier_sku
                                         and supplier_id = :supplier_id and discontinue_on is null',
                                   original_supplier_sku: self.original_supplier_sku,
                                   supplier_id: self.supplier_id).count
            else
              Spree::Variant.where('original_supplier_sku = :original_supplier_sku and id != :id
                                         and supplier_id = :supplier_id and discontinue_on is null',
                                   original_supplier_sku: self.original_supplier_sku,
                                   id: self.id,
                                   supplier_id: self.supplier_id).count
            end

    count.zero?
  end

  # This is specific to the variant and does not factor its parents
  def has_images?
    self.images.count.positive?
  end

  def upc_or_retailer_assigned_upc
    if self.upc.present?
      val = self.upc
    elsif self.retailer_assigned_upc
      val = self.retailer_assigned_upc
    end
    val.to_s.strip
  end

  # We use the SKU directly if it's valid
  def upc_from_sku_or_direct_upc
    if self.upc.present?
      val = self.upc
    elsif self.original_supplier_sku.present? && self.original_supplier_sku.ean?
      val = self.original_supplier_sku
    end
    val.to_s.strip
  end

  def price_based_on_retailer(_retailer)
    # return price unless retailer.setting_charge_suppliers_cost_price
    # self.master_cost || self.cost_price
    self.price
  end

  def supplier_shopify_identifier
    self.shopify_identifier
  end

  def supplier_internal_identifier
    self.supplier&.internal_identifier
  end

  def product_internal_identifier
    self.product&.internal_identifier
  end

  def json_for_global_cache
    JSON.parse(
      self.to_json(only: %i(
                        platform_supplier_sku original_supplier_sku price_management
                        cost_price msrp_price product_internal_identifier
                        available_on discontinue_on
                        supplier_brand_name
                        internal_identifier
),
                   methods: %i(supplier_shopify_identifier supplier_internal_identifier))
    )
  end

  # We want to stay consistent with our SKUs
  def self.upcase_supplier_and_platform_skus!
    ActiveRecord::Base.connection.execute(
      'UPDATE spree_variants SET original_supplier_sku=upper(original_supplier_sku)'
    )
    ActiveRecord::Base.connection.execute(
      'UPDATE spree_variants SET platform_supplier_sku=upper(platform_supplier_sku)'
    )
  end

  # Cost derived from VariantCost
  # Master does not refer to the Spree's traditional master - rather
  # the supplier's master file
  attr_accessor :variant_cost

  def has_cost?
    @variant_cost ||= variant_cost_for_variant
    @variant_cost.present?
  end

  def variant_cost_for_variant
    return nil if self.original_supplier_sku.blank?

    Spree::VariantCost.find_by(
      supplier_id: self.supplier_id,
      sku: self.original_supplier_sku&.upcase
    )
  end

  def master_cost
    @variant_cost ||= variant_cost_for_variant
    @variant_cost&.cost
  end

  # For legacy calculations
  def master_cost_or_legacy_cost
    @variant_cost ||= variant_cost_for_variant
    @variant_cost&.cost || self.cost_price
  end

  def master_msrp
    @variant_cost ||= variant_cost_for_variant
    @variant_cost&.msrp
  end

  def master_map
    @variant_cost ||= variant_cost_for_variant
    @variant_cost&.minimum_advertised_price
  end

  def change_sku_for_testing!
    return if ENV['DROPSHIPPER_ENV'] == 'production'

    self.original_supplier_sku = SecureRandom.hex
    self.save
  end

  def shopify_link
    "https://#{self.supplier&.shopify_url}/admin/products/#{self.product&.shopify_identifier}"
  end

  # We don't want Spree to help us with any inventory tracking
  def should_track_inventory?
    false
  end
end
