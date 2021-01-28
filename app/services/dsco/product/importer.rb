module Dsco
  module Product
    class Importer
      include Spree::Calculator::PriceCalculator
      attr_accessor :current_product, :supplier, :row, :processed_products_ids

      def initialize(supplier)
        @current_product = nil
        @processed_products_ids = []
        @supplier = supplier
      end

      def perform(row)
        @row = row
        if new_product?
          upsert_product
          unless processed_products_ids.include?(current_product.id)
            processed_products_ids << current_product.id
          end
        end
        upsert_variant
        check_discontinued
        true
      end

      def check_discontinued
        discontinued_vals = current_product.variants.map { |v| v.discontinue_on }

        # if all variants are discontinued (non have nil discontinue on) then discontinue the product
        if !discontinued_vals.include?(nil)
          current_product.update(discontinue_on: Time.now)
        end
      end

      def upsert_product
        @current_product = Spree::Product.find_or_initialize_by(
          dsco_identifier: row['dsco_product_id'],
          supplier_id: supplier.id
        )

        current_product.update_attributes(
          name: "#{row['product_title']} - #{row['category']}",
          shipping_category_id: shipping_category.id,
          description:  (row['brand'] + row['mpn']),
          price:  row['cost'],
          supplier_product_type:  row['category'],
          supplier_brand_name:  row['brand'],
          image_urls:  image_urls.compact,
          option_types:  option_types
        )
        current_product.save
      end

      def new_product?
        current_product.nil? || current_product.dsco_identifier != row['dsco_product_id']
      end

      def shipping_category
        @shipping_category ||= Spree::ShippingCategory.find_or_create_by(name: 'Default')
      end

      def option_types
        res = []
        %w(attribute_name_1 attribute_name_2 attribute_name_3).each do |attribute_name|
          next unless row[attribute_name].present?

          name = row[attribute_name].capitalize
          res << Spree::OptionType.find_or_create_by(
            name: name, presentation: name
          )
        end
        res
      end

      def upsert_variant
        return unless current_product.present?

        variant = Spree::Variant.find_or_initialize_by(
          dsco_identifier: row['dsco_item_id'],
          product_id: current_product.id
        )

        variant.update_attributes(variant_attributes(row))

        create_stock_item(variant, row['quantity_available'])
      end

      def variant_attributes(row)
        instance_type = @supplier.instance_type
        markup_percentage = @supplier.default_markup_percentage
        price = row['cost'].to_f
        {
          msrp_price: calc_msrp_price(price, nil, instance_type, markup_percentage),
          msrp_currency: 'USD',
          cost_price: calc_cost_price(price, instance_type, markup_percentage),
          price: calc_price(price, instance_type, markup_percentage),
          original_supplier_sku: row['sku'],
          platform_supplier_sku: "#{row['sku']}-#{supplier.brand_short_code}",
          upc: row['upc'],
          discontinue_on: discontinue_on(row['status']),
          option_values: option_values,
          supplier_color_value: color_value(row),
          supplier_size_value: size_value(row),
          supplier_category_value: row['category'],
          supplier_id: supplier.id,
          weight: row['weight'],
          weight_unit: weight_unit(row['weight_units']),
          image_urls: image_urls.compact
        }
      end

      def color_value(row)
        (1..3).each do |n|
          return row["attribute_value_#{n}"] if row["attribute_name_#{n}"]&.downcase == 'color'
        end
      end

      def size_value(row)
        (1..3).each do |n|
          return row["attribute_value_#{n}"] if row["attribute_name_#{n}"]&.downcase == 'size'
        end
      end

      def weight_unit(unit)
        mapping = { 'LBS' => 'lb' }
        mapping[unit]
      end

      def image_urls
        %w(image_reference_1 image_reference_2 image_reference_3).map do |ref|
          row[ref] unless row[ref].blank?
        end
      end

      def discontinue_on(dsco_status)
        case dsco_status
        when 'discontinued'
          DateTime.now
        when 'in-stock'
          nil
        end
      end

      def create_stock_item(variant, quantity_available)
        # Spree uses stock items to keep track of inventory
        variant.stock_items.where(count_on_hand: 0).destroy_all
        variant_stock_location = Spree::StockLocation.where(
          supplier_id: supplier.id
        ).first_or_create! do |stock_location|
          stock_location.name = "#{supplier.name}'s Default Warehouse"
          stock_location.active = true
          stock_location.backorderable_default = true
          stock_location.propagate_all_variants = false
        end
        stock_item = Spree::StockItem.where(
          stock_location_id: variant_stock_location.id,
          variant_id: variant.id
        ).first_or_create!

        stock_item.count_on_hand = quantity_available
        stock_item.save
      end

      def option_values
        res = []
        option_type_names = {}
        %w(attribute_name_1 attribute_name_2 attribute_name_3).each do |attribute_name|
          option_type_names[attribute_name] = row[attribute_name]
        end
        option_type_names.each do |key, value|
          next unless value.present?

          option_type = current_product.option_types.where(name: value.capitalize).first
          next unless option_type.present?

          name = key.gsub('name', 'value')
          value = row[name]
          option_value = Spree::OptionValue.find_or_create_by(
            name: value.upcase,
            option_type_id: option_type.id
          )
          option_value.update(presentation: value) unless option_value.presentation.present?

          res << option_value
        end
        res
      end
    end
  end
end
