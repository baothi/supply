module Shopify
  module Product
    class StatusChecker
      include Shopify::Helpers

      # Results
      attr_accessor :found
      attr_accessor :published
      attr_accessor :has_inventory
      attr_accessor :quantity

      attr_accessor :local_product

      attr_accessor :shopify_variants
      attr_accessor :shopify_product

      def initialize(opts = {})
        validate(opts)

        @found = false
        @published = false
        @has_inventory = false
        @quantity = 0
      end

      def validate(opts)
        raise 'Product Required' if opts[:product].nil?

        @local_product = opts[:product]

        @supplier = @local_product.supplier
        raise 'Supplier Required' if @supplier.nil?
      end

      def update_local_variant_quantity(shopify_variant)
        local_variant = Spree::Variant.
                        find_by_shopify_identifier_and_supplier_id(shopify_variant.id, @supplier.id)
        quantity = translate_shopify_inventory_amount(shopify_variant)
        local_variant.update_variant_stock(quantity) unless
            local_variant.nil?
      end

      #def check_inventory_status
      #  if @local_product.count_on_hand.zero?
      #    @local_product.discontinue_on = DateTime.now
      #    @local_product.save!
      #  elsif @local_product.count_on_hand.positive? && @local_product.discontinue_on.present?
      #    @local_product.discontinue_on = nil
      #    @local_product.save!
      #  end
      #end

      def check_publishable_status
        if @shopify_product.published_at.nil?
          @local_product.discontinue_on = DateTime.now
          @local_product.save!
        elsif @shopify_product.published_at.present? && @local_product.discontinue_on.present?
          @local_product.discontinue_on = nil
          @local_product.save!
        end
      end

      def perform
        begin
          @supplier.initialize_shopify_session!

          product_shopify_identifier = @local_product.shopify_identifier
          return if product_shopify_identifier.blank?

          @shopify_product = ShopifyAPI::Product.find(product_shopify_identifier)
          @shopify_product.variants.each do |variant|
            update_local_variant_quantity(variant)
          end

          # check_inventory_status
          check_publishable_status

          @found = true
          @published = !@shopify_product.published_at.nil?
          @quantity = @local_product.count_on_hand
          @has_inventory = !@quantity.zero?

          @supplier.destroy_shopify_session!
        rescue => ex
          puts "#{ex}".red
        end
      end

      def available?
        @published && @found && !@quantity.zero?
      end
    end
  end
end
