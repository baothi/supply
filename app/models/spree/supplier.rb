module Spree
  class Supplier < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    include CommitWrap
    include CommonBusiness

    # Shopify
    include Shopify::Initializers
    include Shopify::Monitor

    include InternalIdentifiable
    include Spree::Suppliers::InternalVendorNumberable

    # For generating fake supplier names
    include Spree::Suppliers::Pseudonymable
    include Spree::Suppliers::SellingPermissionScope

    # For option value management
    include Spree::Suppliers::CategoryOptionManagement
    include Spree::Suppliers::ColorOptionManagement
    include Spree::Suppliers::SizeOptionManagement
    include Spree::Suppliers::LicenseOptionManagement

    # Constansts
    include Spree::Suppliers::Constants

    include Spree::Team::FriendlyModelName

    # Retailer & Suppliers Shared Methods
    include Spree::RetailersAndSuppliers::Teamable
    include Spree::RetailersAndSuppliers::ShopifyCacheable
    include Spree::RetailersAndSuppliers::ShopifyInstallable

    after_create :set_brand_short_code

    after_create :send_welcome_email
    after_create :schedule_referral_emails

    has_many :line_items

    has_many :team_members, as: :teamable, dependent: :destroy
    has_many :users, through: :team_members

    has_one :stripe_customer, as: :strippable
    has_one :shopify_credential, as: :teamable
    has_one :woo_credential, as: :teamable
    has_many :webhooks, as: :teamable

    has_many :orders
    has_many :retailer_order_reports

    has_many :products
    has_many :variants
    has_many :product_listings

    # Settings Capabilities
    include Settings::Settingable

    setting :inventory_buffer, :integer, default: 5
    # For finding which suppliers are our licensed
    setting :exclusively_sells_licensed_products, :boolean, default: false
    # For default setting which Sales Channels are created for each supplier
    setting :all_retailers_can_sell, :boolean, default: false

    # Shipping Zones that this supplier allows their products to be sold to
    has_many :shipping_zone_eligibilities,
             dependent: :destroy
    has_many :shipping_zones,
             through: :shipping_zone_eligibilities, source: :zone,
             class_name: 'Spree::Zone'
    accepts_nested_attributes_for :shipping_zones

    # We have many Shipping Categories & Methods per Supplier
    # At some point we will want to introduce our 'master', categories & methods
    has_many :shipping_categories, dependent: :destroy
    has_many :shipping_methods, dependent: :destroy

    has_many :reseller_agreements

    validates :email, :name, presence: true
    validates :website, http_url: true

    attr_encrypted :tax_identifier,
                   key: ENV['TAX_IDENTIFIER_ENCRYPTION_KEY']&.first(32),
                   algorithm: 'aes-256-gcm',
                   mode: :per_attribute_iv,
                   insecure_mode: true

    enum instance_type: { wholesale: 'Wholesale Instance', ecommerce: 'eCommerce Instance' }
    enum shopify_product_unique_identifier: { sku: 'sku', barcode: 'barcode' }

    has_attached_file :logo,
                      styles: {
                          thumb: '100x100>',
                          square: '500x500#'
                      },
                      default_url: ENV['DEFAULT_PHOTO']

    validates_attachment_content_type :logo, content_type: /\Aimage\/.*\Z/

    scope :active, -> { where(active: true) }
    scope :awaiting_access, -> { where(access_granted_at: nil) }
    scope :having_access, -> { where.not(access_granted_at: nil) }
    scope :exclusively_sells_licensed_products, -> {
      where("settings ->> 'exclusively_sells_licensed_products'='true'")
    }

    scope :all_retailers_can_sell, -> {
      where("settings ->> 'all_retailers_can_sell'='true'")
    }

    # TODO: Introduce concept of 'hingeto_supplier' if they don't use any integrations
    def platform
      return 'dsco' if self.dsco_identifier.present?
      return 'edi' if self.edi_identifier.present?
      return 'revlon' if self.slug == 'revlon-juicy'
      return 'shopify' if self.shopify_credential.present?
    end

    def shopify_supplier?
      platform == 'shopify'
    end

    def edi_supplier?
      platform == 'edi'
    end

    def dsco_supplier?
      platform == 'dsco'
    end

    def revlon_supplier?
      platform == 'revlon'
    end

    def can_ship_to_canada?
      shipping_zones.include?(Spree::Zone.canada)
    end

    def can_ship_to_usa?
      shipping_zones.include?(Spree::Zone.usa)
    end

    def can_ship_to_rest_of_world?
      shipping_zones.include?(Spree::Zone.rest_of_world)
    end

    # Can ship to Canada + ROW
    def can_ship_internationally?
      can_ship_to_canada? && can_ship_to_rest_of_world?
    end

    def cannot_ship_internationally?
      !can_ship_internationally?
    end

    def eligible_shipping_zones_list
      shipping_zones.map(&:name).join(', ')
    end

    # TODO: Look for ways to optimize speed of this
    # e.g. everytime there's shipping zone updated,
    # cache list of countries on the supplier directly
    def can_ship_to_country?(country_code)
      return false if country_code.nil?

      country = Spree::Country.where(iso: country_code.upcase).first

      return false if country.nil?

      countries = self.shipping_zones.map(&:country_list).flatten.uniq
      countries.include? country
    end

    def display_name
      return super if super.present?

      name
    end

    def listings_for_index(filtering_params)
      products = Spree::Product.by_supplier(self.id)

      filtering_params.each do |key, value|
        # puts "Key: #{key} Value: #{value}".blue
        products = products.public_send(key, value) if value.present?
      end

      puts "#{products.to_sql}".magenta

      puts "Found #{products.count} of products".red

      products
    end

    def number_of_referrals
      Spree::RetailerReferral.where(spree_supplier_id: self.id).count
    end

    def allow_free_shipping_for_samples?
      allow_free_shipping_for_sample_products?
    end

    def allow_free_shipping_for_sample_products?
      allow_free_shipping_for_samples
    end

    # TODO: Use background job

    def download_shopify_products_now!(download_images = false)
      ActiveRecord::Base.transaction do
        job = download_shopify_products_job(download_images)
        execute_after_commit do
          Shopify::BulkProductImportWorker.new.perform(job.internal_identifier, run_sync: true)
        end
      end
    end

    def download_shopify_products!(download_images = false)
      ActiveRecord::Base.transaction do
        job = download_shopify_products_job(download_images)
        execute_after_commit do
          Shopify::BulkProductImportWorker.perform_async(job.internal_identifier)
        end
      end
    end

    def download_single_shopify_product!(identifier)
      shopify_product = ShopifyAPI::Product.find(identifier)
      Shopify::Product::Importer.new(supplier: self,
                                     import_single: true,
                                     shopify_identifier: identifier,
                                     download_images: false).perform(shopify_product)
    rescue => e
      puts e.to_s.red
      nil
    end

    def download_shopify_product_images!(force_refresh = false)
      ActiveRecord::Base.transaction do
        job = download_shopify_product_images_job(force_refresh)
        execute_after_commit do
          Shopify::Image::BulkImportJob.perform_later(job.internal_identifier)
        end
      end
    end

    def download_shopify_products_job(download_images = false)
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        option_1: 'mass',
        option_2: download_images,
        supplier_id: self.id,
        teamable_type: 'Spree::Supplier',
        teamable_id: self.id
      )
    end

    def download_shopify_product_images_job(force_refresh = false)
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'images_import',
        initiated_by: 'system',
        option_1: force_refresh,
        supplier_id: self.id
      )
    end

    def self.clear_all_products!
      raise 'Cannot run in production' if ENV['RAILS_ENV'] == 'production'

      Spree::Product.unscoped.delete_all
      Spree::Variant.unscoped.delete_all
      Spree::VariantListing.unscoped.delete_all
      Spree::ProductListing.unscoped.delete_all
      Spree::Favorite.unscoped.delete_all
      puts 'Deleted everything'.blue
    end

    def default_address
      address = address1
      address += ', ' + address2 if address2.present?
      address += ', ' + city if city.present?
      address += ', ' + state if state.present?
      address += ', ' + zipcode if zipcode.present?
      address += ', ' + country if country.present?
      address.strip if address.present?
    end

    def update_shipping_method_names!
      Spree::ShippingCategory.where(supplier_id: self.id).find_each do |shipping_category|
        next if shipping_category.name == 'Default'

        category_name = generate_friendly_name_owned_by_supplier(shipping_category.name)
        shipping_category.update(
          name: category_name
        )
      end
    end

    def update_shipping_category_names!
      Spree::ShippingMethod.where(supplier_id: self.id).find_each do |shipping_method|
        next if shipping_method.name == 'Default'

        shipping_method_name = generate_friendly_name_owned_by_supplier(shipping_method.name)
        shipping_method.update(
          name: shipping_method_name
        )
      end
    end

    def generate_friendly_name_owned_by_supplier(nameable)
      "[#{self.name}] - #{nameable}"
    end

    def update_shipping_category_and_method_names!
      update_shipping_method_names!
      update_shipping_category_names!
    end

    def download_images_for_products_with_empty_image_array!(perform_now = false)
      num = self.products.where("image_urls = '{}'").count
      puts "There are #{num} products without images".yellow
      self.products.where("image_urls = '{}'").each do |p|
        job = p.create_image_download_job
        if perform_now
          Shopify::DownloadProductImageUrlsJob.perform_now(job.internal_identifier)
        else
          Shopify::DownloadProductImageUrlsJob.perform_later(job.internal_identifier)
        end
      end
    end

    def default_markup_percentage
      return super if super.present?

      0.4
    end

    def num_products
      products.count
    end

    def num_orders
      orders.count
    end

    def upload_shipping_methods(file)
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.new(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          supplier_id: self.id
        )
        job.input_csv_file = file
        return false unless job.save

        execute_after_commit do
          Shipping::ShippingMethodsImporterJob.perform_later(job.internal_identifier)
        end
      end
    end

    def download_shipping_methods
      job = Spree::LongRunningJob.new(
        action_type: 'export',
        job_type: 'products_export',
        initiated_by: 'user',
        supplier_id: self.id
      )
      return false unless job.save

      Shipping::ShippingMethodsExporterJob.perform_later(job.internal_identifier)
    end

    def set_brand_short_code
      # code = name.split('').reject(&:blank?).sample(4).map(&:upcase).join('')
      return if brand_short_code.present?

      code = (0...5).map { ('a'..'z').to_a[rand(26)] }.join.upcase
      set_brand_short_code if Spree::Supplier.find_by(brand_short_code: code).present?
      self.update(brand_short_code: code)
    end

    def fix_shopify_pricing
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        supplier_id: self.id
      )
      Pricing::FixSupplierPriceJob.perform_later(job.internal_identifier)
    end

    def self.all_remit_orders_via_suppliers
      Spree::Supplier.where(transmit_orders_to_supplier_via_edi: true)
    end

    def num_recently_created_products
      products.where('created_at > :created_at',
                     created_at: DateTime.now - 1.hours).count
    end

    def discontinue_products_and_variants!
      products.update_all(discontinue_on: Time.now)
      variants.update_all(discontinue_on: Time.now)
    end

    def send_welcome_email
      SupplierMailer.welcome(id).deliver_later
    end

    def schedule_referral_emails
      SupplierMailer.invite_retailers(id).deliver_later(wait: 24.hours)
    end

    def add_team_member(user_params, role_id)
      user = Spree::User.create(user_params.merge(using_temporary_password: true))
      team_member = team_members.create(user_id: user.id, role_id: role_id) if
          user && user.persisted?
      return false unless team_member

      ::UserMailer.invite_new_user(self, user, user_params[:password], id).deliver_later
    end
  end
end
