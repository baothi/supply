module Shopify
  module Variant
    class Importer
      include Shopify::Helpers

      def initialize(opts = {})
        validate(opts)
        puts 'Initializing Variant IMporter'.red
        @local_product = opts[:local_product]
        @shopify_product = opts[:shopify_product]
        @supplier = @local_product.supplier

        @option_types = get_option_types

        @variant_errors = ''
        @shopify_variants = @shopify_product.variants
      end

      def validate(opts)
        raise 'Shopify Product required' if opts[:shopify_product].nil?
        raise 'Local Product required' if opts[:local_product].nil?
      end

      def perform
        puts 'Time to perform'.yellow
        return if @shopify_variants.blank?

        puts 'Discontinued variants'
        discontinue_variants

        @shopify_variants.each do |shopify_variant|
          puts "Syncing: #{shopify_variant.id}".yellow
          sync(shopify_variant)
        end

        @variant_errors
      end

      def sync(shopify_variant)
        begin
          local_variant = Spree::Variant.
                          find_or_initialize_by(shopify_identifier: shopify_variant.id)
          @local_product.sku = nil if @local_product.sku.blank?
          puts "#{local_variant.new_record?}".yellow
          create_variant(local_variant, shopify_variant) if local_variant.new_record?
          update_variant(local_variant, shopify_variant) unless local_variant.new_record?

          update_variant_stock(local_variant, shopify_variant)
          # create_listing(local_variant)
          # For Inventory Management
          create_stock_item(local_variant, shopify_variant)
        rescue => e
          @variant_errors << " #{e} for variant #{shopify_variant.id}"
        end
      end

      def create_variant(local_variant, shopify_variant)
        local_variant.assign_attributes(
          original_supplier_sku: original_supplier_sku(shopify_variant, @supplier),
          platform_supplier_sku: platform_supplier_sku(shopify_variant, @supplier),
          barcode: shopify_variant.barcode,
          product: @local_product,
          supplier_id: @local_product.supplier_id,
          msrp_price: return_msrp_price(shopify_variant, @supplier),
          msrp_currency: 'USD',
          cost_price: set_basic_cost(shopify_variant.price.to_f, @supplier),
          price: price(shopify_variant.price, @supplier),
          weight: shopify_variant.weight,
          weight_unit: shopify_variant.weight_unit
        )

        option_values = extract_option_values(shopify_variant)
        set_options_and_values(local_variant, option_values)

        local_variant.save!
      end

      def update_variant(local_variant, shopify_variant)
        attrs = {
          original_supplier_sku: original_supplier_sku(shopify_variant, @supplier),
          platform_supplier_sku: platform_supplier_sku(shopify_variant, @supplier),
          barcode: shopify_variant.barcode,
          weight: shopify_variant.weight,
          weight_unit: shopify_variant.weight_unit
        }

        price_attrs = {
          msrp_price: return_msrp_price(shopify_variant, @supplier),
          msrp_currency: 'USD',
          cost_price: set_basic_cost(shopify_variant.price.to_f, @supplier),
          price: price(shopify_variant.price, @supplier)
        }

        attrs = attrs.merge(price_attrs) if local_variant.price_management == 'shopify'

        local_variant.update_attributes(attrs)

        option_values = extract_option_values(shopify_variant)
        set_options_and_values(local_variant, option_values)

        local_variant.save!
      end

      def set_options_and_values(local_variant, option_values)
        option_values.each_with_index do |name, index|
          spree_option_type = create_option_type(@option_types[index])
          spree_option_value = create_option_value(name, spree_option_type)
          # create_supplier_option(spree_option_type.name, spree_option_value.name, local_variant)

          local_variant.option_values << spree_option_value unless
              local_variant.option_values.include? spree_option_value
          @local_product.option_types << spree_option_type unless
              @local_product.option_types.include? spree_option_type
        end
      end

      def extract_option_values(shopify_variant)
        [shopify_variant.option1, shopify_variant.option2, shopify_variant.option3].compact
      end

      def create_option_type(name)
        spree_option_type = Spree::OptionType.find_or_create_by(name: name.capitalize)
        spree_option_type.update(presentation: name) unless spree_option_type.presentation.present?
        spree_option_type
      end

      def create_option_value(name, option_type)
        name = name.upcase unless name == 'Default Title'
        option_value = Spree::OptionValue.find_or_create_by(
          name: name,
          option_type_id: option_type.id
        )
        option_value.update(presentation: name) unless option_value.presentation.present?
        option_value
      end

      def get_option_types
        @shopify_product.options.map(&:name)
      end

      def create_stock_item(local_variant, shopify_variant)
        # Spree uses stock items to keep track of inventory
        variant_stock_location = Spree::StockLocation.where(
          supplier_id: local_variant.supplier_id
        ).first_or_create! do |stock_location|
          stock_location.name = "#{local_variant.supplier.name}'s Default Warehouse"
          stock_location.active = true
          stock_location.backorderable_default = true
          stock_location.propagate_all_variants = false
        end
        variant_stock_item = Spree::StockItem.where(
          stock_location_id: variant_stock_location.id,
          variant_id: local_variant.id
        ).first_or_create! do |variant|
          variant.count_on_hand = translate_shopify_inventory_amount(shopify_variant)
        end

        variant_stock_item
      end

      def update_variant_stock(variant, shopify_variant)
        variant_stock_item = variant.stock_items.first_or_create do |stock_item|
          stock_item.stock_location = Spree::StockLocation.first
        end
        variant_stock_item.update(
          count_on_hand: translate_shopify_inventory_amount(shopify_variant)
        )
      end

      def discontinue_variants
        local_variants_ids = @local_product.variants.pluck(:shopify_identifier).map(&:to_i)
        shopify_variants_ids = @shopify_product.variants.map(&:id)

        # Find difference in Id
        discontinued_variants_ids = local_variants_ids - shopify_variants_ids
        discontinued_variants_ids.each do |variant_id|
          variant = Spree::Variant.find_by(shopify_identifier: variant_id)
          variant&.update(discontinue_on: Time.now)
        end
      end
    end
  end
end
