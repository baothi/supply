module Spree
  class ProductListing < ApplicationRecord
    include InternalIdentifiable
    include IntervalSearchScopes

    include Spree::ProductListings::AdminSearchable
    after_commit :check_retailer_created_first_product, on: :create

    belongs_to :product, class_name: 'Spree::Product'
    belongs_to :retailer
    belongs_to :supplier

    has_many :variant_listings

    validates_presence_of :shopify_identifier

    def self.default_scope
      where(deleted_at: nil)
    end

    def update_shopify_title!
      begin
        shopify_product = CommerceEngine::Shopify::Product.find(self.shopify_identifier)

        raise 'Invalid shopify product' if shopify_product.nil?

        self.shopify_handle = shopify_product.handle
        self.save!
      rescue => ex
        puts "#{ex}".red
      end
    end

    def self.update_variant_listings_set_product_ids!
      listings = Spree::VariantListing.all.where('product_listing_id is null')
      listings.each do |variant_listing|
        product_listing = Spree::ProductListing.where(
          retailer_id: variant_listing.retailer_id,
          product_id: variant_listing.variant.product_id
        ).first

        if product_listing.nil?
          puts "Could not found product listing for Variant Listing: #{variant_listing.id}"
          next
        end
        variant_listing.product_listing_id = product_listing.id
        variant_listing.save!
      end
    end

    def create_variant_listing(local_variant, shopify_variant)
      begin
        variant_listing = local_variant.retailer_listing(self.retailer_id)
        return if variant_listing.present?

        supplier_id = local_variant&.supplier&.id
        raise 'Supplier is required to create variant listing' if supplier_id.nil?

        listing = Spree::VariantListing.unscoped.find_or_initialize_by(
          variant_id: local_variant.id,
          retailer_id: self.retailer.id,
          supplier_id: supplier_id,
          product_listing_id: self.id
        )

        listing.update(shopify_identifier: shopify_variant.id, deleted_at: nil)

        listing.save!
      rescue => e
        puts "create_variant_listing: #{e}".red
      end
    end

    def export_new_variant(local_variant, shopify_product)
      puts "exporting variant: #{local_variant.id}".magenta
      begin
        shopify_product.variants
      rescue
        shopify_product.variants = []
      end

      begin
        shopify_variant = ShopifyAPI::Variant.new(
          variant_params(local_variant)
        )

        puts "#{shopify_variant.inspect}".magenta
        shopify_product.variants << shopify_variant
        shopify_product.save!

        # TODO: Need to ensure that this works
        shopify_variant = shopify_product.variants.last
        # export_variant_image(local_variant, shopify_variant, shopify_product)
        create_variant_listing(local_variant, shopify_variant)
      rescue => ex
        puts "export_new_variant: #{ex}".red
      end

      # shopify_product.variants << shopify_variant
      # shopify_product.save!
      # shopify_product
    end

    def variant_params(local_variant)
      {
          title: local_variant.name,
          option1: local_variant.first_option_value,
          option2: local_variant.second_option_value,
          sku: local_variant.platform_supplier_sku,
          # barcode: local_variant.barcode,
          inventory_management: 'shopify',
          inventory_quantity: local_variant.count_on_hand,
          price: local_variant.price * 2,
          weight: local_variant.weight,
          weight_unit: local_variant.weight_unit
      }
    end

    def resync_variants_with_shopify_listing!
      begin
        local_product = self.product
        raise 'Cannot sync this listing due to missing product' if
            local_product.nil?

        retailer = self.retailer
        retailer.initialize_shopify_session!

        shopify_product = ShopifyAPI::Product.find(self.shopify_identifier)

        self.variant_listings.map(&:destroy)

        shopify_product.variants.each do |shopify_variant|
          # Ensure listing doesn't somehow exist
          existing_listing = Spree::VariantListing.find_by(
            retailer_id: self.retailer_id,
            shopify_identifier: shopify_variant.id
          )

          next unless existing_listing.nil?

          # First find local variant
          local_variant = Spree::Variant.find_local_variant(
            local_product,
            shopify_variant
          )

          if local_variant.nil?
            puts 'Local Variant not found!'.red
            next
          end

          create_variant_listing(local_variant, shopify_variant)
        end

        retailer.destroy_shopify_session!
      rescue => ex
        puts "Unable to sync: #{ex}".red
      end
    end

    def check_retailer_created_first_product
      retailer = Spree::Retailer.find_by_id(self.retailer_id)
      if retailer.has_product_listing != true
        job = Spree::LongRunningJob.create(action_type: 'import',
                                     job_type: 'email_notification',
                                     initiated_by: 'user',
                                     teamable_type: 'Spree::Retailer',
                                     retailer_id: self.retailer_id,
                                     supplier_id: self.supplier_id,
                                     option_1: self.product_id)
        ::Retailer::FirstProductEmailJob.perform_later(job.internal_identifier)
        retailer.update_attributes(has_product_listing: true)
      end
    end

  end
end
