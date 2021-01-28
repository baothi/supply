module SoleSociety
  module Variant
    class Importer
      include Spree::Calculator::PriceCalculator

      attr_reader :file, :supplier

      OPTION_TYPES = {
        'size': 'Size',
        'gender': 'Gender',
        'color': 'Color'
      }.freeze

      def initialize(file, supplier)
        @file = file
        @supplier = supplier
        @product = nil
        @supplier.set_brand_short_code
      end

      def perform
        i = 0
        CSV.foreach(file, encoding: 'iso-8859-1:utf-8',  headers: true, skip_blanks: true) do |row|
          i = i + 1
          break if i > 10 && Rails.env.development?
          next unless allowed_to_sell(row)

          begin
            if new_product?(row)
              upsert_product(row)
              add_option_types_to_product(row)
            end
            variant = upsert_variant(row)
            download_product_image if ENV['DOWNLOAD_SOLE_SOCIETY_IMAGES'] == 'true'
          rescue => e
            puts "#{e}".red
            Rollbar.error(e, product_name: product&.name, variant_gtin: row['gtin']&.to_s)
          end
        end
      end

      private

      attr_accessor :product

      def upsert_product(row)
        @product = Spree::Product.find_or_initialize_by(
          vendor_style_identifier: row['item_group_id'],
          supplier_id: supplier.id
        )
        assign_attributes_from_row(row)
      end

      def assign_attributes_from_row(row)
        product.name = row['mpn']
        product.supplier_brand_name = row['brand']
        product.supplier_product_type = extract_friendly_supplier_category(row['product_type'])
        product.shipping_category_id = shipping_category.id
        product.description = row['brand'] + row['mpn']
        product.price = row['price']
        product.image_urls << row['image_link'] unless
            product.image_urls.include? row['image_link']
        product.save
      end

      # Sole Society has an unnecessary product_type that includes things like color at the end
      # (e.g. Shoes > Booties > Titanium)
      # This method seeks to simply return the part of this that we care about so that
      # generated shipping methods are easy to handle

      def extract_friendly_supplier_category(raw_category)
        return '' if raw_category.nil?

        raw_category.split('>').each(&:strip!)[0..1].join(' > ')
      end

      # def discontinue_on(sole_society_status)
      #   case sole_society_status
      #   when 'out of stock'
      #     DateTime.now
      #   when 'in stock'
      #     nil
      #   end
      # end

      def upsert_variant(row)
        variant = Spree::Variant.find_or_initialize_by(
          original_supplier_sku: row['gtin'],
          gtin: row['gtin'],
          product_id: product.id
        )

        # Original Supplier
        # variant.supplier_category_value = extract_friendly_supplier_category(row['product_type'])

        variant.assign_attributes(variant_attributes(row))

        # This also saves the variant
        add_option_values_to_variant(variant, row)

        # For now we assign 1000 because we do not have access to the stock number
        create_stock_item(variant, 1000)

        variant
      end

      def variant_attributes(row)
        instance_type = @supplier.instance_type
        markup_percentage = @supplier.default_markup_percentage
        price = row['price'].to_f
        {
            msrp_price: calc_msrp_price(price, nil, instance_type, markup_percentage),
            msrp_currency: 'USD',
            cost_price: calc_cost_price(price, instance_type, markup_percentage),
            price: calc_price(price, instance_type, markup_percentage),
            original_supplier_sku: row['gtin'],
            platform_supplier_sku: "#{row['gtin']}-#{supplier.brand_short_code}",
            upc: nil,
            discontinue_on: nil, # discontinue_on(row['availability']),
            supplier_id: @supplier.id,
            supplier_category_value: extract_friendly_supplier_category(row['product_type']),
            supplier_color_value: row['color'],
            supplier_size_value: row['size']
        }
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
        stock_item.save!
      end

      def add_option_types_to_product(_row)
        OPTION_TYPES.values.each do |value|
          option_type = Spree::OptionType.find_or_create_by(
            name: value, presentation: value
          )
          next if option_type.nil?

          product.option_types << option_type unless product.option_types.include? option_type
        end
        product.save!
      end

      def add_option_values_to_variant(variant, row)
        OPTION_TYPES.each do |key, value|
          next unless row[key.to_s].present?

          option_type = product.option_types.where(name: value).first
          next if option_type.nil?

          puts "Looking for: row: #{row.inspect}".blue
          puts "Looking for: key: #{key}".blue
          puts "Looking for: joint: #{row[key.to_s]}".blue
          option_value = Spree::OptionValue.find_or_create_by(
            name: row[key.to_s]&.upcase,
            option_type_id: option_type.id
          )
          option_value.presentation = row[key.to_s] unless option_value.presentation.present?
          option_value.save!

          variant.option_values = []
          variant.option_values << option_value unless variant.option_values.include? option_value
        end
        variant.save!
      end

      def download_product_image
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'images_import',
          initiated_by: 'user',
          option_1: product.id
        )
        Shopify::ImportProductImageJob.perform_later(job.internal_identifier)
      end

      def shipping_category
        @shipping_category ||= Spree::ShippingCategory.find_or_create_by(name: 'Default')
      end

      def new_product?(row)
        product.nil? || !product.name.eql?(row['mpn'])
      end

      def allowed_to_sell(row)
        return false unless  row['product_type'].present?

        allowed_categories = %w(Bags Shoes)
        main_category = row['product_type'].split('>').each(&:strip!).first
        row['brand'] == 'Sole Society' && allowed_categories.include?(main_category)
      end
    end
  end
end
