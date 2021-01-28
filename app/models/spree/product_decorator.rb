require 'algoliasearch'

Spree::Product.class_eval do
  include InternalIdentifiable
  include Spree::Products::SearchScope
  include Spree::Products::SellingPermissionScope
  include Spree::Products::SearchAttributable

  include AlgoliaSearch

  include CommitWrap

  # Settings Capabilities
  include Settings::Settingable

  # Product Compliance
  include Spree::Products::MarketplaceCompliance

  # Approval Workflow
  include AASM
  include Spree::Products::ApprovalWorkflow

  # Fields for searching in active admin
  include Spree::Products::AdminSearchable
  include Spree::Products::Countable
  include Spree::Calculator::PriceCalculator

  include Spree::Products::Reporting # Product Reporting
  include Csvable

  # Option Management
  include Spree::Products::CategoryOptionable
  include Spree::Products::ColorOptionable
  include Spree::Products::SizeOptionable

  setting :shopify_price_updates, :boolean, default: true
  setting :shopify_inventory_updates, :boolean, default: true

  setting :shopify_title_updates, :boolean, default: true
  setting :shopify_properties_updates, :boolean, default: true
  setting :shopify_availablity_updates, :boolean, default: true

  has_many :product_listings
  has_many :favorites
  has_many :product_export_processes
  has_many :stock_item_tracking

  belongs_to :supplier, class_name: 'Spree::Supplier'

  attr_accessor :shopify_variants

  scope :available, -> {
    where('spree_products.discontinue_on is NULL')
  }

  scope :unavailable, -> {
    where('discontinue_on < ?', Time.now)
  }

  scope :not_discontinued_and_pending_review, -> {
    not_discontinued.pending_review
  }

  scope :not_discontinued_and_pending_review_with_images, -> {
    not_discontinued.pending_review.with_images
  }

  scope :not_discontinued_and_pending_review_without_images, -> {
    not_discontinued.pending_review.without_images
  }

  scope :marketplace_compliant, -> {
    where('spree_products.marketplace_compliant = true')
  }

  scope :submission_compliant, -> {
    where('spree_products.submission_compliant = true')
  }

  scope :marketplace_compliant_and_pending_review, -> {
    marketplace_compliant.pending_review
  }

  scope :marketplace_compliant_and_approved, -> {
    marketplace_compliant.approved
  }

  scope :variant_original_supplier_sku_is, ->(search) {
    Spree::Product.search_by_original_supplier_sku(search)
  }

  after_commit :check_deactivated_products

  # For ActiveAdmin
  def self.ransackable_scopes(_auth_object = nil)
    %i(variant_original_supplier_sku_is)
  end

  before_save :set_supplier_product_type
  # after_touch :index!

  # Set status of variants to deleted
  before_destroy :validate_candidacy_for_deletion
  after_destroy :mark_all_variants_as_deleted!
  after_destroy :mark_cache_as_deleted!

  unless Rails.env.test?
    algoliasearch per_environment: true do
      attribute :internal_identifier, :sku, :name, :description, :slug,
                :shopify_identifier, :shopify_vendor, :license_name,
                :shopify_product_type, :supplier_internal_identifier, :propercase_name,
                :submission_state, :supplier_brand_name, :supplier_name

      add_attribute :listing_image
      add_attribute :product_variants
      add_attribute :license_taxons
      add_attribute :category_taxons
      add_attribute :custom_collection_taxons
      add_attribute :stock_quantity
      add_attribute :last_five_internal_identifier
      add_attribute :eligible_for_international_sale

      customRanking ['desc(created_at)']
      attributesForFaceting ['internal_identifier', 'stock_quantity',
                             'eligible_for_international_sale',
                             'license_taxons.id', 'license_taxons.name',
                             'category_taxons.id', 'category_taxons.name',
                             'custom_collection_taxons.id', 'supplier_internal_identifier',
                             'submission_state', 'supplier_name', 'supplier_brand_name']
    end
  end

  # Currently tied to supplier
  # TODO: We may want to have both supplier level and product level control
  def shopify_product?
    supplier&.shopify_supplier?
  end

  # Currently tied to supplier
  # TODO: We may want to have both supplier level and product level control
  def product_platform
    return nil if supplier.nil?

    supplier.platform
  end

  def self.search_by_original_supplier_sku(sku)
    Spree::Product.joins(:variants).where("spree_variants.original_supplier_sku iLIKE '%#{sku}%'")
  end

  # THis is used to keep track of the original value set by the supplier
  def set_supplier_product_type
    return if self.supplier_product_type.present?

    self.supplier_product_type = self.shopify_product_type if
        self.shopify_product_type.present?
  end

  # Forces new refresh of Algolia Indices
  def self.refresh_indices!
    self.available.approved.reindex
  end

  def eligible_for_international_sale
    self.supplier&.can_ship_internationally?
  end

  def eligible_for_international_sale?
    eligible_for_international_sale
  end

  def product_variants
    self.variants.map do |variant|
      { sku: variant.sku, platform_supplier_sku: variant.platform_supplier_sku,
        barcode: variant.barcode, shopify_identifier: variant.shopify_identifier,
        internal_identifier: variant.internal_identifier,
        submission_compliant: variant.submission_compliant,
        marketplace_compliant: variant.marketplace_compliant }
    end
  end

  def listing_image
    master.listing_image
  end

  def license_taxons
    self.taxons.is_license.map do |taxon|
      { id: taxon.id, name: taxon.name }
    end
  end

  def category_taxons
    self.taxons.is_category.map do |taxon|
      { id: taxon.id, name: taxon.name }
    end
  end

  def custom_collection_taxons
    self.taxons.is_custom_collection.map do |taxon|
      { id: taxon.id, name: taxon.name }
    end
  end

  def stock_quantity
    available_quantity
  end

  def available_quantity
    sum = self.variants.not_discontinued.sum(&:available_quantity)
    sum
  end

  def last_five_internal_identifier
    internal_identifier[-5..-1] if internal_identifier
  end

  def self.trigger_sidekiq_worker(record, remove)
    # AlgoliaIndexJob.perform_async(record.id, remove)
  end

  def self.unpublish_unavailable
    unavailable_products = Spree::Product.unavailable
    return if unavailable_products.blank?

    unavailable_products.each(&:unpublish)
  end

  def unpublish
    return unless self.discontinued?

    job = create_unpublish_running_job
    Shopify::UnpublishJob.perform_later(job.internal_identifier)
  end

  def create_unpublish_running_job
    Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'user',
      option_1: self.id
    )
  end

  # TODO: Need to save this / use db column to set.
  # For now, we take MSRP of first variant
  def msrp_price
    first_variant = self.try(:variants).first
    return 1.4 * self.price if first_variant.nil?

    first_variant.try(:msrp_price)
  end

  def commission_from_dropshipping
    return 0 if master.nil?

    master.msrp_price.to_f - master.price.to_f
  end

  def retailer_listing(retailer_id)
    product_listings.where(retailer_id: retailer_id).first
  end

  def live?(retailer_id)
    product_listings.where(retailer_id: retailer_id).present?
  end

  def retailer_favorite?(retailer)
    Spree::Favorite.where(retailer_id: retailer.id, product_id: self.id).present?
  end

  # Move to service
  def download_product_and_variants_from_shopify
    ro = ResponseObject.failure_response_object('N/A')
    begin
      self.supplier.initiatialize_shopify_session
      product_shopify_identifier = self.shopify_identifier
      return ro if product_shopify_identifier.blank?

      shopify_product = ShopifyAPI::Product.find(product_shopify_identifier)

      if shopify_product.published_at.nil?
        ro.message = 'This product is not published'
        return ro
      end

      # Save Variants
      ro.data_object = shopify_product
      ro.data_object2 = shopify_product.variants
      ro.success!
    rescue => ex
      puts "#{ex}".red
      ro.fail!
    end
    ro
  end

  def available_quantity
    sum = self.variants.sum(&:available_quantity)
    sum
  end

  # TODO: Update this to work like valid_count_on_hand
  def count_on_hand
    sum = self.variants.sum(&:count_on_hand)
    sum
  end

  def valid_count_on_hand
    sum = self.variants.not_discontinued.sum(&:count_on_hand)
    sum
  end

  def can_be_added_to_store?
    !available_quantity.zero? && discontinue_on.nil? && variants.not_discontinued.count.positive?
  end

  def export_in_progress?(retailer)
    export_process = Spree::ProductExportProcess.where(retailer: retailer, product: self).first
    export_process.present? && export_process.in_progress?
  end

  def create_export_process(retailer)
    export_process = Spree::ProductExportProcess.find_or_create_by(
      retailer: retailer,
      product: self
    )
    export_process.reschedule_export! if export_process.completed?
  end

  def locate_export_in_progress(retailer)
    export_process = Spree::ProductExportProcess.where(retailer: retailer, product: self).first
    export_process
  end

  def sync_with_shopify!
    status_checker = Shopify::Product::StatusChecker.new(product: self)
    status_checker.perform
  end

  def image_attachment_urls
    return [] if images.empty?

    images.first(10).map(&:original_photo_url).compact
  end

  def create_listing(shopify_id, retailer_id)
    begin
      return if self.retailer_listing(retailer_id).present?

      listing = Spree::ProductListing.unscoped.find_or_initialize_by(
        product_id: self.id,
        retailer_id: retailer_id,
        supplier_id: self.supplier_id
      )
      listing.update(shopify_identifier: shopify_id,  deleted_at: nil)
      listing.save!
      listing
    rescue
      nil
    end
  end

  def supplier_internal_identifier
    return nil if self.supplier.nil?

    self.supplier.internal_identifier
  end

  # TODO: Replace

  def propercase_name
    return '' if name.nil?
    # TODO: Move this to a supplier settings
    return name if self&.supplier&.name == 'Bioworld'

    name.propercase
  end

  # TODO: Replace

  def propercase_description
    return '' if description.nil?
    return description if self&.supplier&.name == 'Bioworld'

    white_list_sanitizer = Rails::Html::WhiteListSanitizer.new
    # We sanitize to re-covert tags like <P> to <p>
    sanitized_desc = white_list_sanitizer.sanitize(description.propercase)
    sanitized_desc.to_s
  end

  # Used for takedowns
  # Spree::Product.where(license_name: 'Anime PLS').map {|p| puts p.submission_state }

  def supplier_name
    self.supplier&.name
  end

  def num_product_listings
    product_listings.count
  end

  def num_variants
    variants.count
  end

  def sync_product_in_background!
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_4: self.shopify_identifier,
      supplier_id: self.supplier_id
    )

    Shopify::ProductUpdateWorker.perform_async(job.internal_identifier)
  end

  def sync_product_now!
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'system',
      option_4: self.shopify_identifier,
      supplier_id: self.supplier_id
    )
    Shopify::ProductUpdateWorker.new.perform(job.internal_identifier)
  end

  def download_shopify_product_images!
    job = download_shopify_product_images_job
    Shopify::Image::SingleImportJob.perform_later(job.internal_identifier)
  end

  def download_shopify_product_images_job
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'images_import',
      initiated_by: 'system',
      option_1: self.id,
      supplier_id: self.supplier_id
    )
  end

  def takedown_all_product_listings!
    self.product_listings.each do |product_listing|
      begin
        retailer = Spree::Retailer.find(product_listing.retailer_id)
        retailer.initialize_shopify_session!

        shopify_product = CommerceEngine::Shopify::Product.find(product_listing.shopify_identifier)
        if shopify_product.nil?
          msg = "Nil shopify product for product_listing: #{product_listing.id}. "\
            'Skipping unpublishing'
          puts "#{msg}".yellow
          next
        end

        shopify_product.destroy
        # Remove it's variant listings first
        product_listing.variant_listings.each do |vl|
          vl.deleted_at = DateTime.now
          vl.save!
        end
        product_listing.deleted_at = DateTime.now
        product_listing.save!

        retailer.destroy_shopify_session!
      rescue => ex
        puts "Issue: #{ex}".red
      end
    end
  end

  def no_variant?
    return false if variants.count > 1
    return unless variants.count == 1

    variants.first.presentation == 'Default Title'
  end

  def default_variant
    return if variants.count > 1 || variants.count.zero?
    return unless no_variant?

    variants.first
  end

  def touch_taxons
    # puts 'Skipping touch_taxons'.yellow
  end

  def create_image_download_job
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      option_1: self.internal_identifier
    )
    job
  end

  def shopify_image_urls_param
    images.map { |i| { src: i.attachment_url(:original) } }
  end

  def shopify_params(retailer)
    {
      title: name,
      bodyHtml: description,
      tags: %w(dicentral teamup),
      productType: self.platform_category_option&.name,
      vendor: product_license_or_vendor(retailer),
      images: shopify_image_urls_param,
      options: shopify_options_param,
      metafields: shopify_metafields(retailer)
    }
  end

  def product_license_or_vendor(retailer)
    retailer.can_view_brand_name? ? self.brand_name_to_export : alt_brand_name_to_export
  end

  def shopify_metafields(retailer)
    [
      { key: 'supplier_name',
        value: metafield_key_to_value('supplier_name', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier' },
      {
        key: 'cost_price',
        value: metafield_key_to_value('cost_price', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'us_base_shipping_cost',
        value: metafield_key_to_value('us_base_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'us_add_on_shipping_cost',
        value: metafield_key_to_value('us_add_on_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'canada_base_shipping_cost',
        value: metafield_key_to_value('canada_base_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'canada_add_on_shipping_cost',
        value: metafield_key_to_value('canada_add_on_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'row_base_shipping_cost',
        value: metafield_key_to_value('row_base_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      },
      {
        key: 'row_add_on_shipping_cost',
        value: metafield_key_to_value('row_add_on_shipping_cost', retailer).to_s,
        valueType: 'STRING',
        namespace: 'hingeto:supplier'
      }
    ]
  end

  def metafield_key_to_value(key, retailer)
    case key
    when 'supplier_name' then get_supplier_name(retailer)
    when 'cost_price' then price_based_on_retailer(retailer)
    when 'us_base_shipping_cost' then shipping_method&.first_item_us
    when 'us_add_on_shipping_cost' then shipping_method&.additional_item_us
    when 'canada_base_shipping_cost' then shipping_method&.first_item_canada
    when 'canada_add_on_shipping_cost' then shipping_method&.additional_item_canada
    when 'row_base_shipping_cost' then shipping_method&.first_item_rest_of_world
    when 'row_add_on_shipping_cost' then shipping_method&.additional_item_rest_of_world
    else ''
    end
  end

  def get_supplier_name(retailer)
    retailer.can_view_brand_name? ? supplier&.name : supplier&.display_name
  end

  def price_based_on_retailer(_retailer)
    variants.map(&:master_cost).compact.max
  end

  def shipping_method
    shipping_category.shipping_methods.last
  end

  def brand_name_to_export
    supplier_brand_name || license_name || supplier&.name
  end

  def alt_brand_name_to_export
    supplier_brand_name || license_name || supplier&.display_name
  end

  def shopify_options_param
    %w(Color Size)
  end

  def available_variants
    variants.not_discontinued
  end

  def available_and_submission_compliant_variants
    variants.not_discontinued_and_submission_compliant
  end

  def available_and_not_submission_compliant_variants
    variants.not_discontinued_and_not_submission_compliant
  end

  def available_and_in_stock_variants
    available_variants.in_stock.distinct
  end

  # TODO: This may need to be changed to factor for Variant images.
  def has_images?
    self.images.count.positive?
  end

  def default_variant_product?
    variants.count == 1 && variants.first.option_values.map(&:name) == ['Default Title'] &&
      variants.first.option_values.count == 1
  end

  def convert_default_title_to_color_size
    variant = variants.first
    variant.set_option_value('Size', 'OS')
    variant.set_option_value('Color', 'MULTI')
  end

  # Deletion-related methods.

  def validate_candidacy_for_deletion
    if self.product_listings.count.positive? || self.orders.count.positive?
      errors.add(:base,
                 I18n.t('products.error.deletion_not_allowed'))
      puts 'Product has orders/product listings'.red
      return false
    end
    true
  end

  def mark_all_variants_as_deleted!
    self.variants.update_all(deleted_at: DateTime.now)
  end

  def mark_cache_as_deleted!
    return if self.shopify_identifier.blank?

    begin
      ShopifyCache::Product.find(
        self.shopify_identifier.to_i
      )&.mark_as_deleted!
    rescue => ex
      ErrorService.new(exception: ex).perform
    end
  end

  def supplier_shopify_identifier
    self.shopify_identifier
  end

  def json_for_global_cache
    JSON.parse(
      self.to_json(only: %i(name description
                            supplier_brand_name
                            supplier_shopify_identifier
                            available_on discontinue_on
                            internal_identifier),
                   methods: %i(supplier_name available_quantity supplier_internal_identifier
                               supplier_brand_name))
    )
  end

  def check_deactivated_products
    deactivated_products = Spree::ProductListing.joins("inner join spree_products sp on sp.id = spree_product_listings.product_id").
                              where("retailer_id = spree_product_listings.retailer_id").
                              where("sp.discontinue_on >= ?", DateTime.now - 30.seconds)
                              .pluck(:product_id,:retailer_id)
    deactivated_products.concat( Spree::Favorite.joins("inner join spree_products sp on sp.id = spree_favorites.product_id").
                              where("sp.discontinue_on >= ?", DateTime.now - 30.seconds)
                              .pluck(:product_id,:retailer_id))
    # [[24, 3], [24, 6], [24, 13], [25,7],[25,8]].group_by { |i| i[0] }.map do |k,v|
    #     v.flatten.uniq
    # end
    deactivated = []
    deactivated_products.group_by { |i| i[0] }.map do |k,v|
      deactivated << v.flatten.uniq
    end
     # [[24, 3, 6, 13], [25, 7, 8]]
     # [[19, 4], [17, 4], [58, 35], [58, 25], [58, 11], [58, 35]]
    return if deactivated_products.empty?
    job = Spree::LongRunningJob.create(action_type: 'import',
                                     job_type: 'email_notification',
                                     initiated_by: 'user',
                                     teamable_type: 'Spree::Retailer',
                                     array_option_1: deactivated)
    ::Products::SendMailDeactivatedProductJob.perform_later(job.internal_identifier)
  end
end
