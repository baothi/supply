module Shopify
  module Audit
    class DefaultVariantRemover
      # require 'celluloid/current'
      #
      # include Celluloid

      attr_accessor :retailer, :errors, :logs

      def initialize(opts = {})
        @retailer = opts[:retailer]
        @from = opts[:from]
        @variants = []
        @removed_product_ids = []
        @errors = ''
        @logs = ''
      end

      def validate
        raise 'Retailer must be set' if @retailer.nil?
      end

      # Alias
      def audit
        perform
      end

      def perform_async(opts)
        @retailer = opts[:retailer]
        @from = opts[:from]
        @variants = []
        perform
      end

      def connect_to_shopify
        raise 'Could not connect to shopify' unless
            @retailer.initialize_shopify_session!
      end

      def disconnect_from_shopify
        @retailer.destroy_shopify_session!
      end

      def extract_default_variants(variants)
        variants.select do |v|
          options = [v.option1, v.option2, v.option3].compact
          case options
          when ['Default'], ['Default', 'Default'], ['Default', 'Default', 'Default']
            true
          end
        end
      end

      def extract_zero_price_variants(variants)
        variants.reject do |v|
          v.price.to_f.positive?
        end
      end

      def find_all_shopify_products
        products = CommerceEngine::Shopify::Product.find(
          :all,
          params: { limit: 250, created_at_min: @from }
        )
        products
      end

      def process_products(products)
        mxed_products = products.map.select { |product| product.tags.include?('mxed') }

        mxed_products.each do |product|
          check_product_and_variants_validity_and_action_as_necessary!(product)
        end
      end

      def perform
        validate

        begin
          connect_to_shopify

          products = find_all_shopify_products
          process_products(products)

          while products.next_page?
            products = products.fetch_next_page
            process_products(products)
          end

          puts "#{@removed_product_ids.count} products found and deleted for #{@retailer.name} "\
            "- #{@retailer.id}".red
          if @removed_product_ids.count.positive?
            ProductsMailer.products_removed_from_shopify(
              @retailer.id,
              @removed_product_ids
            ).deliver_later
          end
          disconnect_from_shopify
        rescue => ex
          puts "#{ex} for retailer: #{@retailer.name} - #{@retailer.id}".red
        end
      end

      def check_product_and_variants_validity_and_action_as_necessary!(shopify_product)
        if has_missing_images?(shopify_product) ||
           has_zero_price_variants?(shopify_product) ||
           has_default_variants?(shopify_product)
          remove_locally_and_remotely_at_shopify!(shopify_product)
        end
      end

      def has_missing_images?(shopify_product)
        puts "Removing #{shopify_product.title} due to no images!".yellow if
            shopify_product.images.count.zero?
        shopify_product.images.count.zero?
      end

      def has_zero_price_variants?(shopify_product)
        zero_price_variants =
          extract_zero_price_variants(shopify_product.variants)
        puts "Removing #{shopify_product.title} due to zero variants".yellow if
            zero_price_variants.count.positive?
        zero_price_variants.count.positive?
      end

      def has_default_variants?(shopify_product)
        shopify_variants = shopify_product.variants
        default_variants = extract_default_variants(shopify_variants)
        puts "Removing #{shopify_product.title} due to default variants".yellow if
            default_variants.count.positive?
        default_variants.count.positive?
      end

      def remove_locally_and_remotely_at_shopify!(shopify_product)
        begin
          # Find local product listing if it exists
          product_listing =
            Spree::ProductListing.find_by(
              shopify_identifier: shopify_product.id,
              retailer_id: @retailer.id
            )
          local_product = product_listing&.product

          # Unlist this product and its affiliated variants locally
          removed_locally = nil
          if product_listing
            removed_locally = unlist_local_product(product_listing)
            puts "Successfully removed locally: #{product_listing.internal_identifier}".yellow
          end

          # Remove this product at shopify
          removed_from_shopify = remove_at_shopify(shopify_product)

          # Add to list of products that were remvoed
          @removed_product_ids << local_product.id if removed_locally && removed_from_shopify

          true
        rescue => e
          @errors << " #{e}\n"
          puts "#{@errors}".red
          false
        end
      end

      def remove_at_shopify(shopify_product)
        begin
          ShopifyAPIRetry.retry(3) { shopify_product.destroy }
          true
        rescue => e
          @errors << " #{e}\n"
          puts "#{@errors}".red
          false
        end
      end

      def unlist_local_product(product_listing)
        begin
          return if product_listing.nil?

          variant_listings = product_listing.variant_listings
          variant_listings.each do |l|
            l.update(deleted_at: Time.now)
          end
          product_listing.update(deleted_at: Time.now)
          true
        rescue => e
          @errors << " #{e}\n"
          puts "#{@errors}".red
          false
        end
      end
    end
  end
end
