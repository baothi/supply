# This purpose of this service is to recreate a CSV order into its Shopify Equivalent
# Used by Karmaloop upload tool
module Karmaloop
  module Order
    class Recreator
      def initialize(opts = {})
        validate(opts)
        @retailer = opts[:retailer]
        @lines = opts[:lines]
      end

      def validate(opts)
        raise 'Invalid Retailer' if opts[:retailer].blank?
        raise 'Invalid Line Items' if opts[:lines].blank?
      end

      def process_line(line)
        begin
          # email = extract_email(line)
          line[:shipping_email] = 'karmaloop@hingeto.com'
          line[:phone] = 'N/A'
          line_items = create_line_items(line)
          shipping_address = extract_shipping(line)

          # Create Order with This information & save

          shopify_order = CommerceEngine::Shopify::Order.create(order_params(line))
          shopify_order.line_items = line_items
          shopify_order.shipping_lines = []
          shopify_order.shipping_address = shipping_address
          shopify_order.save!
        rescue => ex
          puts "#{ex}".red
        end
      end

      def extract_email(line)
        line[:shipping_email]
      end

      def extract_shipping(line)
        address = build_address(
          first_name: line[:first_name],
          last_name: line[:last_name],
          address1: line[:address1],
          address2: line[:address2],
          city: line[:city],
          zip: ZipCodeConverter.convert(line[:zip], line[:state]),
          state: line[:state],
          country: line[:country],
          province: line[:province],
          phone: 'N/A'
        )
        address
      end

      def convert_to_local_variants(line)
        skus = line[:part_number].split(',')
        local_variants = []
        skus.each do |sku|
          puts "Looking for #{sku.strip}"
          variants = Spree::Variant.where(platform_supplier_sku: sku.strip)
          if variants.count > 1
            puts 'More than 1 variant found for: '\
              "#{sku.strip}. You may want to double check color/size".yellow
          end
          raise "Unable to find variant for #{sku.strip}" if variants.nil? || variants.empty?

          local_variants << variants.first
        end
        local_variants
      end

      def create_line_items(line)
        local_variants = convert_to_local_variants(line)

        # Now Find the Corresponding Variant Listing at the
        # Retailer's store for this product

        shopify_line_items = []
        local_variants.each do |local_variant|
          variant_listing = local_variant.retailer_listing(@retailer.id)
          raise 'Unable to locate listing' if variant_listing.nil?

          puts "checking shopify for this variant #{variant_listing.shopify_identifier}".blue

          shopify_variant =
            CommerceEngine::Shopify::Variant.find(variant_listing.shopify_identifier)

          shopify_line_items <<
            CommerceEngine::Shopify::LineItem.create(
              line_item_params(line, shopify_variant)
            )
        end

        puts "#{shopify_line_items}".magenta
        shopify_line_items
      end

      def perform
        begin
          puts 'Processing Time'.blue
          @retailer.init
          @lines.each do |line|
            process_line(line)
          end
          @retailer.destroy_shopify_session!
        rescue => ex
          puts "#{ex}".red
        end
      end

      def order_params(opts)
        {
          email: opts[:shipping_email],
          customer: {
            "first_name": opts[:shipping_first_name],
            "last_name": opts[:shipping_last_name],
            "email": opts[:shipping_email]
          },
          total_price: 50,
          subtotal_price: 50,
          tags: 'hingeto, karmaloop',
          financial_status: 'paid',
          note: 'This order originally came from Karmaloop & was re-created in MXED.',
          note_attributes:  {
              "Karmaloop Invoice ID":  opts[:invoice_id]
          }
        }
      end

      def line_item_params(line_item, shopify_variant)
        {
          variant_id: shopify_variant.id,
          title: line_item[:title],
          quantity: line_item[:quantity],
          order_number: line_item[:invoice_id],
          product_id: shopify_variant.product_id,
          name: shopify_variant.title,
          price: 50 / 3.to_f
        }
      end

      def get_shopify_variant(line_item)
        variant = line_item.variant
        begin
          ShopifyAPI::Variant.find(variant.shopify_identifier)
        rescue
          @error << "Could not find corresponding MXED variant \n"
          nil
        end
      end

      def build_address(opts)
        addr = {
          address1: opts[:address1],
          address2: opts[:address2],
          first_name: opts[:first_name],
          last_name: opts[:last_name],
          country: opts[:country],
          phone:  'N/A',
          company:  opts[:company],
          zip:  ZipCodeConverter.convert(opts[:zip], opts[:state]),
          province:  opts[:state],
          city:  opts[:city],
          default: true
        }
        puts "Address: #{addr}"
        addr
      end
    end
  end
end
