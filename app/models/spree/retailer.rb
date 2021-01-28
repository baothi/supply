module Spree
  class Retailer < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: :slugged

    include CommitWrap
    include CommonBusiness

    include FriendlyError
    include InternalIdentifiable
    include Spree::Retailers::Constants
    include Spree::Retailers::SellingPermissionScope
    before_create :add_unsubscribe_hash

    # Shopify
    include Shopify::Initializers
    include Shopify::Monitor

    include Spree::Team::FriendlyModelName

    include IntervalSearchScopes

    include Spree::Retailers::Reporting # For data analysis
    include Spree::Retailers::Inventories
    include Spree::Retailers::Listings

    # Settings Capabilities
    include Settings::Settingable

    # Retailer & Suppliers Shared Methods
    include Spree::RetailersAndSuppliers::Teamable
    include Spree::RetailersAndSuppliers::ShopifyCacheable
    # Shopify Installation/Uninstallation
    include Spree::RetailersAndSuppliers::ShopifyInstallable

    acts_as_follower

    has_many :team_members, as: :teamable, dependent: :destroy
    has_many :users, through: :team_members

    has_many :favorites

    has_one :stripe_customer, as: :strippable
    has_one :shopify_credential, as: :teamable
    has_one :woo_credential, as: :wooteamable
    has_many :webhooks, as: :teamable

    has_many :stripe_cards, through: :stripe_customer

    has_many :line_items

    has_many :product_export_processes

    has_many :orders, inverse_of: :retailer

    belongs_to :legal_entity_address, class_name: 'Spree::Address'
    belongs_to :shipping_address, class_name: 'Spree::Address'

    accepts_nested_attributes_for :legal_entity_address
    accepts_nested_attributes_for :shipping_address

    attr_encrypted :tax_identifier,
                   key: ENV['TAX_IDENTIFIER_ENCRYPTION_KEY']&.first(32),
                   algorithm: 'aes-256-gcm',
                   mode: :per_attribute_iv,
                   insecure_mode: true

    validates :email, :name, presence: true
    validates :website, http_url: true

    has_many :reseller_agreements

    has_many :retailer_order_reports
    has_one :retailer_credit, dependent: :destroy

    has_many :mapped_shipping_methods, as: :teamable

    # after_create :send_welcome_email
    # after_create :schedule_referral_emails

    scope :has_remindable_unpaid_orders, -> {
      joins(:orders).
        select('spree_retailers.id, spree_retailers.email, spree_retailers.name').
        merge(Spree::Order.remindable_unpaid_orders).
        distinct
    }

    scope :relies_on_shopify_product_metafields, -> {
      json_value = { relies_on_shopify_product_metafields: true }.to_json
      where('settings @> ?', json_value)
    }

    scope :has_paid_and_completed_onboarding, -> {
      paying_subscriber.completed_onboarding
    }
    scope :paying_subscriber_and_has_not_completed_onboarding, -> {
      paying_subscriber.has_not_completed_onboarding
    }
    scope :not_paying_subscriber, -> { where(current_stripe_subscription_identifier: nil) }
    scope :paying_subscriber, -> { where.not(current_stripe_subscription_identifier: nil) }
    scope :has_not_completed_onboarding, -> { where(completed_onboarding_at: nil) }
    scope :completed_onboarding, -> { where.not(completed_onboarding_at: nil) }
    scope :awaiting_access, -> { where(access_granted_at: nil) }
    scope :having_access, -> { where.not(access_granted_at: nil) }

    setting :skip_payment_for_orders, :boolean, default: false
    setting :charge_suppliers_cost_price, :boolean, default: false
    setting :send_shopify_fulfillment_notice, :boolean, default: true
    setting :enable_15_minute_inventory_updates, :boolean, default: false
    setting :relies_on_shopify_product_metafields, :boolean, default: false

    # For onboarding flow. Did not want to create new migration
    setting :downloaded_guide, :boolean, default: false

    # Pricing Plan Features

    delegate :has_credit?, :total_available_credit, to: :retailer_credit, allow_nil: true

    def platform
      # return 'dsco' if self.dsco_identifier.present?
      # return 'edi' if self.edi_identifier.present?
      return 'shopify' if self.shopify_credential.present?
    end

    def shopify_retailer?
      platform == 'shopify'
    end

    def owner_user
      team_members.find_by(role_id: Spree::Role.find_by(name: RETAILER_OWNER).try(:id)).try(:user)
    end

    def number_of_referrals
      Spree::SupplierReferral.where(spree_retailer_id: self.id).count
    end

    def following_licenses
      license_taxons_id = Spree::Taxon.is_license.pluck(:id)
      follows_scoped.
        where(followable_type: 'Spree::Taxon').
        where('followable_id IN (?)', license_taxons_id).
        map(&:followable)
    end

    def following_categories
      category_taxons_ids = Spree::Taxon.is_category.pluck(:id)
      follows_scoped.
        where(followable_type: 'Spree::Taxon').
        where('followable_id IN (?)', category_taxons_ids).
        map(&:followable)
    end

    def self.locate_by_host(_host)
      Spree::Retailer.first
    end

    def favorite_products
      Spree::Product.with_deleted.joins(:favorites).where(spree_favorites: { retailer_id: self.id })
    end

    def add_team_member(user_params, role_id)
      user = Spree::User.create(user_params.merge(using_temporary_password: true))
      team_member = team_members.create(user_id: user.id, role_id: role_id) if
                    user && user.persisted?
      return false unless team_member

      ::UserMailer.invite_new_user(self, user, user_params[:password], id).deliver_later
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

    def default_address_model
      Spree::Address.new(
        address1: address1,
        address2: address2,
        city: city,
        zipcode: zipcode,
        phone: phone,
        state_name: state,
        alternative_phone: phone_number,
        name_of_state: state
      )
    end

    # Helpers for Address
    def name_of_state
      self.state
    end

    def country_iso
      self.country
    end

    def us_retailer?
      self.country&.downcase == 'us'
    end

    def canadian_retailer?
      self.country&.downcase == 'ca'
    end

    def rest_of_world_retailer?
      !(us_retailer? || canadian_retailer?)
    end

    # Both Canada & ROW
    def international_retailer?
      !us_retailer?
    end

    # TODO: Change this
    def eligible_to_sell_product?(product)
      return false if product.nil?

      supplier = product.supplier
      return false if supplier.nil?
      return false if !us_retailer? && supplier.cannot_ship_internationally?

      true
    end

    def eligible_for_sample_order_free_shipping?
      orders.sample_orders_for_this_month.count <= 3
    end

    def num_free_shipping_samples_used
      orders.sample_orders_for_this_month.count
    end

    # Orders

    def num_shopify_orders_in_last(days)
      count = shopify_klass_counter('ShopifyAPI::Order',
                                    DateTime.now - days.days,
                                    DateTime.now, true)
      count
    end

    def shopify_klass_counter(klass, from, to, init = true)
      puts 'hello'.yellow
      self.initialize_shopify_session! if init
      client = klass.constantize
      count =
        ShopifyAPIRetry.retry do
          client.find(
            :all,
            params: { created_at_min: from, created_at_max: to, status: 'any', limit: 250 }
          ).count
        end

      self.destroy_shopify_session! if init
      count
    end

    def last_order_report
      retailer_order_reports.order('created_at desc').first
    end

    def email_legal_proof_to_operations!
      # pdf = ResellerAgreementPdf.new(nil, Spree::Retailer.first).render_file
      self.update_all_listings_titles! unless Rails.env.development?
      pdf = ResellerAgreementPdf.new(nil, self).render
      OperationsMailer.email_legal_proof(self, 'See attached', pdf).deliver!
    end

    def create_missing_orders_job(from, to)
      from ||= DateTime.now - 3.weeks
      to ||= DateTime.now
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'orders_import',
        initiated_by: 'user',
        option_1: from,
        option_2: to,
        retailer_id: self.id
      )
    end

    def look_for_missing_orders(from = nil, to = nil)
      ActiveRecord::Base.transaction do
        job = create_missing_orders_job(from, to)
        execute_after_commit do
          Shopify::Retailer::GhostOrderReportWorker.perform_async(job.internal_identifier)
        end
      end
    end

    def look_for_missing_orders_now(from = nil, to = nil)
      ActiveRecord::Base.transaction do
        job = create_missing_orders_job(from, to)
        execute_after_commit do
          Shopify::Retailer::GhostOrderReportWorker.new.perform(job.internal_identifier)
        end
      end
    end

    def export_all_products_to_shopify_now!
      available_products_to_export = products_to_export

      return unless available_products_to_export.present?

      batch_size =
        ENV['PRODUCT_EXPORT_BATCH_SIZE'].present? ? ENV['PRODUCT_EXPORT_BATCH_SIZE'].to_i : 250

      available_products_to_export.find_in_batches(batch_size: batch_size) do |products|
        # we need an exprt process in product export service class
        products.each { |p| p.create_export_process(self) }

        product_ids = products.pluck(:internal_identifier)
        job = create_long_running_job(product_ids)

        ShopifyExportJob.perform_now(job.internal_identifier)
      end
    end

    def products_to_export
      available_products_ids = Spree::Product.available.pluck(:id)
      listed_products_ids = self.product_listings.pluck(:product_id)

      listed_products_ids = listed_products_ids - listings_missing_on_shopify.pluck(:product_id)
      unlisted_products_ids = available_products_ids - listed_products_ids

      Spree::Product.where(id: unlisted_products_ids)
    end

    def export_all_products_to_shopify!
      available_products_to_export = products_to_export

      return unless available_products_to_export.present?

      batch_size =
        ENV['PRODUCT_EXPORT_BATCH_SIZE'].present? ? ENV['PRODUCT_EXPORT_BATCH_SIZE'].to_i : 250

      available_products_to_export.find_in_batches(batch_size: batch_size) do |products|
        # we need an exprt process in product export service class
        products.each { |p| p.create_export_process(self) }

        product_ids = products.pluck(:internal_identifier)
        job = create_long_running_job(product_ids)

        ShopifyExportJob.perform_later(job.internal_identifier)
      end
    end

    def create_long_running_job(product_ids)
      Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'products_export',
        initiated_by: 'user',
        option_1: product_ids.join(','),
        retailer_id: self.id
      )
    end

    def bulk_adjust_inventory_quantities
      begin
        ActiveRecord::Base.transaction do
          job = create_long_running_job_for_inventory_ingestion
          execute_after_commit do
            Shopify::RetailerBulkInventoryUpdateWorker.perform_async(job.internal_identifier)
          end
        end
      rescue => ex
        puts "#{ex}".red
      end
    end

    def can_view_brand_name?
      can_view_brand_name == true
    end

    def default_us_shipping_method
      default_shipping_method('us')
    end

    def default_canada_shipping_method
      default_shipping_method('canada')
    end

    def default_rest_of_world_shipping_method
      default_shipping_method('rest_of_world')
    end

    def default_shipping_method(region)
      return if region.nil?
      return nil if self["default_#{region}_shipping_method_id"].nil?

      Spree::ShippingMethod.where(
        id: self["default_#{region}_shipping_method_id"]
      ).first
    end

    def create_fulfillment_service
      return unless self.init
      # We assume that we've already created the fulfillment service here
      # TODO: We should also check at Shopify that a fulfillment service
      # called mxed (ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME']) doesn't already exist.
      # but for now, we will skip this step.
      return if self.hingeto_fulfillment_service_created_at.present?

      service = ShopifyAPIRetry.retry(3) do
        ShopifyAPI::FulfillmentService.create(
          name: ENV['HINGETO_SUPPLY_FULFILLMENT_SERVICE_NAME'],
          callback_url: ENV['SHOPIFY_RETAILER_FULFILLMENT_SERVICE_CALLBACK_URL'],
          tracking_support: true,
          requires_shipping_method: true,
          inventory_management: true,
          format: 'json'
        )
      end

      # puts service.inspect

      self.update(
        default_location_shopify_identifier: service.location_id,
        hingeto_fulfillment_service_created_at: DateTime.now,
        shopify_management_switched_to_hingeto_at: DateTime.now
      )
    end

    def switch_variant_management_to_hingeto
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'export',
          job_type: 'products_export',
          initiated_by: 'system',
          retailer_id: id
        )

        execute_after_commit do
          Shopify::Variant::UpdateManagementToHingetoWorker.perform_async(job.internal_identifier)
        end
      end
    end

    # Generate Excel File
    def generate_inventory_audit_file
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'export',
          job_type: 'products_export',
          initiated_by: 'system',
          retailer_id: id
        )

        execute_after_commit do
          Shopify::InventoryAuditForRetailerWorker.perform_async(job.internal_identifier)
        end
      end
    end

    # Generate Excel File - For immediate execution
    def generate_inventory_audit_file_now
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'export',
          job_type: 'products_export',
          initiated_by: 'system',
          retailer_id: id
        )

        execute_after_commit do
          Shopify::InventoryAuditForRetailerWorker.new.perform(job.internal_identifier)
        end
      end
    end

    def licensed_suppliers_list
      access = []
      no_access = []
      Spree::Supplier.exclusively_sells_licensed_products.find_each do |supplier|
        authority = Spree::SellingAuthority.find_by(
          retailer: self,
          permission: 'permit',
          permittable_type: supplier
        )
        if authority
          access << supplier
        else
          no_access << supplier
        end
      end
      [access, no_access]
    end

    def grant_access_to_licensed_suppliers!
      begin
        Spree::Supplier.exclusively_sells_licensed_products.find_each do |supplier|
          Spree::SellingAuthority.find_or_create_by!(
            retailer: self,
            permission: 'permit',
            permittable: supplier
          )
        end
      rescue => ex
        puts "#{ex}".red
        Rollbar.error(ex)
      end
    end

    def grant_access_to_marketplace_suppliers!
      begin
        Spree::Supplier.all_retailers_can_sell.find_each do |supplier|
          Spree::SellingAuthority.find_or_create_by!(
            retailer: self,
            permission: 'permit',
            permittable: supplier
          )
        end
      rescue => ex
        puts "#{ex}".red
        Rollbar.error(ex)
      end
    end

    def completed_onboarding_prep_for_flow_without_specialist(user)
      app_installed = self.shopify_credential.present?
      viewed_guide = self.setting_downloaded_guide
      confirmed_user = user.confirmed?
      result = (app_installed && viewed_guide && confirmed_user)
      result
    end

    def completed_onboarding_prep_for_flow_without_specialist?(user)
      completed_onboarding_prep_for_flow_without_specialist(user)
    end

    def self_onboard!
      # Give access to all suppliers that allow them to sell without permissions
    end


    def update_trial_time!
      return if self.remaining_trial_time == 0

      remaining = self.remaining_trial_time - (Time.now - self.trial_started_on).to_i
      remaining = 0 if remaining < 0
      self.update(remaining_trial_time: remaining)
    end

    def products_discontinued_since(date)
      product_listings
      .joins(:product)
      .where("spree_products.discontinue_on > ?", date )
    end

    private
      def add_unsubscribe_hash
        self.unsubscribe_hash = SecureRandom.hex
      end

    # def send_welcome_email
    #   RetailerMailer.welcome(id).deliver_later
    # end
    #
    # def schedule_referral_emails
    #   RetailerMailer.invite_vendors(id).deliver_later(wait: 24.hours)
    # end
  end
end
