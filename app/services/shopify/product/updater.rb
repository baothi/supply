module Shopify
  module Product
    class Updater
      attr_accessor :supplier, :errors, :logs, :shopify_product

      include Shopify::Helpers

      require 'open-uri'

      def initialize(opts = {})
        @supplier_id = opts[:supplier_id]
        raise 'Supplier required for product update' if @supplier_id.nil?

        @supplier = Spree::Supplier.find_by(id: @supplier_id)
        @shopify_product = opts[:shopify_product]

        @errors = ''
        @logs = ''
      end

      #def check_inventory_status(local_product, shopify_identifier)
      #  return unless local_product.get_setting(:shopify_availablity_updates)
      #
      #  if local_product.count_on_hand.zero?
      #    logs << "Discontinued Product #{shopify_identifier} due to lack of inventory.\n"
      #    local_product.discontinue!
      #  elsif local_product.count_on_hand.positive? && local_product.discontinue_on.present?
      #    logs << "Unhiding Product #{shopify_identifier} due to new inventory.\n"
      #    local_product.discontinue_on = nil
      #    local_product.save!
      #  end
      #end

      def check_publishable_status(local_product, shopify_product, shopify_identifier)
        return unless local_product.get_setting(:shopify_availablity_updates)

        if shopify_product.published_at.nil?
          logs << "Discontinued Product #{shopify_identifier} due to published_at setting .\n"
          local_product.discontinue!
        elsif shopify_product.published_at.present? && local_product.discontinue_on.present?
          logs << "Unhiding Product #{shopify_identifier} due to published_at setting .\n"
          local_product.discontinue_on = nil
          local_product.save!
        end
      end

      def build_shopify_product(shopify_identifier)
        if shopify_product.present?
          puts 'No need for Shopify API call'.yellow
        else
          @shopify_product = ShopifyAPIRetry.retry(3) do
            ShopifyAPI::Product.find(shopify_identifier)
          end
        end
      end

      def perform(shopify_identifier = nil)
        begin
          build_shopify_product(shopify_identifier)

          shopify_identifier ||= shopify_product.id

          local_product = Spree::Product.find_by(shopify_identifier: shopify_identifier)
          raise 'Shopify::Product::Updater: This product is invalid' if local_product.nil?

          # check_inventory_status(local_product, shopify_identifier)
          check_publishable_status(local_product, shopify_product, shopify_identifier)

          shopify_variants = shopify_product.variants
          local_product.update_attributes(
            price: product_price(shopify_product, supplier),
            description: shopify_product.body_html
          )

          shopify_variants.each do |shopify_variant|
            local_variant = Spree::Variant.find_by(shopify_identifier: shopify_variant.id)

            if local_variant.nil?
              local_variant = local_product.variants.find_by(
                original_supplier_sku: original_supplier_sku(shopify_variant, supplier)
              )
              next unless local_variant.present?

              update_local_variant_shopify_identifier(local_variant, shopify_variant)
            end

            update_variant_stock_and_price(local_variant, shopify_variant)
            local_variant.sync_shopify_weight!(shopify_variant)
          end
          true
        rescue => e
          errors << "#{e} \n"
          return false
        end
      end

      def update_variant_stock_and_price(local_variant, shopify_variant)
        logs << "Updating inventory.\n"
        # update_variant_stock(local_variant, shopify_variant)
        logs << "Updating price.\n"
        update_variant_price(local_variant, shopify_variant)
        logs << "Updating Weight.\n"
      end

      def update_variant_stock(variant, shopify_variant)
        return unless variant.product.get_setting(:shopify_inventory_updates)

        variant_stock_item = variant.stock_items.first_or_create do |stock_item|
          stock_item.stock_location = Spree::StockLocation.first
        end
        qty = translate_shopify_inventory_amount(shopify_variant)
        variant_stock_item.update(count_on_hand: qty)
      end

      def update_variant_price(variant, shopify_variant)
        return unless variant.product.get_setting(:shopify_price_updates)

        variant.update_attributes(
          msrp_price: return_msrp_price(shopify_variant, supplier),
          cost_price: set_basic_cost(shopify_variant.price.to_f, supplier),
          price: price(shopify_variant.price, supplier)
        )
      end

      def update_local_variant_shopify_identifier(local_variant, shopify_variant)
        local_variant.update(shopify_identifier: shopify_variant.id)
      end
    end
  end
end
