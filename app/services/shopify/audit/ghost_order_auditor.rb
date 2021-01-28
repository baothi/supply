module Shopify
  module Audit
    class GhostOrderAuditor
      attr_accessor :all_hingeto_orders,
                    :potential_orders_based_on_sku

      def initialize(opts = {})
        @retailer = opts[:retailer]
        @from = opts[:from]
        @to = opts[:to]
        @all_hingeto_orders = []
        # Used to track orders that could be ours due to SKU
        @potential_orders_based_on_sku = []
      end

      def validate
        raise 'Retailer must be set' if @retailer.nil?

        @from ||= DateTime.now - 3.weeks
        @to ||= DateTime.now
        raise 'From Date, must be less than now' if @to < @from
      end

      def previously_imported_line_item?(shopify_identifier)
        Spree::LineItem.find_by(retailer_shopify_identifier: shopify_identifier)
      end

      def perform
        validate

        begin
          # puts "ID: #{@retailer.id}"\
          #   "Name: #{@retailer.name}, "\
          #   "URL: #{@retailer.shopify_url}".blue

          raise 'Could not connect to Shopify' unless @retailer.initialize_shopify_session!

          page = 1
          begin
            orders = CommerceEngine::Shopify::Order.find(
              :all, params: {
                limit: 250,
                created_at_min: @from,
                created_at_max: @to
            }
            )

            filter_for_hingeto_orders(orders)

            while orders.next_page?
              orders = orders.fetch_next_page
              filter_for_hingeto_orders(orders)
              page += 1
              sleep 1 if (page % 5).zero?
            end
          end while orders&.any?

          @retailer.destroy_shopify_session!
        rescue => ex
          puts "#{ex} for retailer: #{@retailer.name} - #{@retailer.id}".red
        end

        print_results
      end

      def print_definitive
        return unless @all_hingeto_orders.count.positive?

        # global_definitive_count = Redis::Counter.new('hingeto::retailer::global_definitive_count')
        #
        #
        # hash_key = Redis::HashKey.new('hingeto::retailer::definitive_orders')

        puts '---Definitive Orders---'.magenta
        @all_hingeto_orders.each do |order|
          puts "Retailer URL: #{admin_url} - Retailer ID:#{@retailer.id} - "\
          "#{@retailer.shopify_url} - "\
          "ID: #{order.id} - Name: #{order.name} - "\
          "Financial Status: #{order.financial_status}".black.on_green
          # @retailer.definitive_orders << order.name
          # hash_key[@retailer.id.to_s] = order.name
          # $redis.sadd('hingeto::retailer::definitive_orders', 1)
        end
        # global_definitive_count.incr(@all_hingeto_orders.count)
      end

      def print_potentials
        return unless @potential_orders_based_on_sku.count.positive?

        # global_potential_count = Redis::Counter.new('hingeto::retailer::global_potential_count')
        # hash_key = Redis::HashKey.new('hingeto::retailer::potential_orders')

        puts '---Probable Orders ---'.magenta
        @potential_orders_based_on_sku.each do |order|
          puts "Retailer URL: #{admin_url} - Retailer ID:#{@retailer.id} - "\
          "#{@retailer.shopify_url} - "\
          "ID: #{order.id} - Name: #{order.name} - "\
          "Financial Status: #{order.financial_status}".black.on_yellow
          # @retailer.potential_orders << order.name
          # hash_key[@retailer.id.to_s] = order.name
        end

        # global_potential_count.incr(@potential_orders_based_on_sku.count)
        # $redis.incr('hingeto::retailer::global_definitive_count')
      end

      def print_results
        if @all_hingeto_orders.count.positive? || @potential_orders_based_on_sku.count.positive?
          puts "Found #{@all_hingeto_orders.count + @potential_orders_based_on_sku.count} "\
            "definitive orders for for #{@retailer.id} - #{@retailer.shopify_url}".yellow
        end

        print_definitive
        print_potentials

        # puts '======='.blue # if
        # @all_hingeto_orders.count.positive? || @potential_orders_based_on_sku

        nil
      end

      def admin_url
        "#{ENV['SITE_URL']}/active/admin/spree_retailers/#{@retailer.slug}"
      end

      def order_text(order)
        "Retailer URL: #{admin_url} - Retailer ID:#{@retailer.id} - "\
          "#{@retailer.shopify_url} - "\
          "ID: #{order.id} - Name: #{order.name} - "\
          "Financial Status: #{order.financial_status}"
      end

      def filter_for_hingeto_orders(shopify_orders)
        return [] if shopify_orders.nil?

        shopify_orders.each do |shopify_order|
          # puts "Checking Order #{shopify_order.id} | #{shopify_order.name} ...".yellow
          # First look to see if we've already brought it in
          # order = Spree::Order.where(retailer_shopify_identifier: shopify_order.id)
          # next if order.present?

          # Now look to see if we have a MXED product
          shopify_order.line_items.each do |shopify_line_item|
            next if previously_imported_line_item?(shopify_line_item.id)

            # next unless shopify_line_item.product_exists
            ro = filter_single_potential_order_from_line_item(shopify_order, shopify_line_item)
            next if ro.successful? # We do not need to look through other line items
          end
        end
      end

      def filter_single_potential_order_from_line_item(shopify_order, shopify_line_item)
        ro = ResponseObject.blank_success_response_object
        begin
          # Skip line items without a product attached
          # as there's no way for us to handle these
          # TODO: Perhaps search in MXED by title if product doesn't exist anymore?

          # puts "#Shopify Line Item: #{shopify_line_item.id} "\
          #   "| Product Present: #{shopify_line_item.product_exists}"\
          #   "| Product product_id: #{shopify_line_item.product_id}"\
          #   "| Product variant_id: #{shopify_line_item.variant_id}".blue

          if shopify_line_item.product_id.present?
            # We do this because we cannot trust Shopify's product_exists parameters
            # During development, itk ept returning true for a deleted product
            begin
              shopify_product = CommerceEngine::Shopify::Product.find(shopify_line_item.product_id)
            rescue
              # puts "Product #{shopify_line_item.product_id} does not actually exist".yellow
              # puts 'Going to try to look for this product by SKU instead'.yellow
              find_local_variant_by_by_sku(shopify_line_item, shopify_order)
              return ro
            end

            # return ro if shopify_product.nil?

            # We don't have an else case for shopify_line_item.variant_id.present?
            # because during experimentation, it seemed as though orders retain the variant_id
            # even when the variant has been deleted at Shopify. So the only reliable source
            # of the original product/variant is either product_id or product_exists

            # Add to collection
            @all_hingeto_orders << shopify_order if
                shopify_product.tags.include?('hingeto') &&
                !@all_hingeto_orders.include?(shopify_order)

          else

            find_local_variant_by_by_sku(shopify_line_item, shopify_order)

            # shopify_variant = CommerceEngine::Shopify::Variant.find(shopify_line_item.variant_id)
            # raise 'No Variant or Product Exists' if
            #     shopify_variant.nil? || shopify_variant.product_id.nil?
            # # Now search by SKU and / or tags
            # shopify_product = CommerceEngine::Shopify::Product.find(shopify_variant.product_id)
          end

          ro.success!
        rescue => ex
          puts "Error: #{ex}".red
          ro.fail!
        end
        ro
      end

      # We now have to try to determine based on the order SKU
      def find_local_variant_by_by_sku(shopify_line_item, shopify_order)
        return if shopify_line_item.sku.blank?

        local_variants = Spree::Variant.where(supplier_sku: shopify_line_item.sku)

        @potential_orders_based_on_sku << shopify_order if
            local_variants.count.positive? &&
            !@potential_orders_based_on_sku.include?(shopify_order)
      end
    end
  end
end
