module Testing
  class ShopifyOrderGenerator
    attr_accessor :failed_orders, :successful_orders, :orders
    def initialize(job_id)
      @job = Spree::LongRunningJob.find(job_id)

      # Not sure if we need to generalize this. We'd really only want to do this for retailers
      klass = @job.teamable_type == 'supplier' ? 'Spree::Supplier' : 'Spree::Retailer'
      @team = klass.constantize.find(@job.teamable_id)
      @num_orders = @job.option_1.to_i

      @job.update(total_num_of_records: @job.option_1)

      # We may want to allow this to vary in the future
      @num_line_items = 1
      @total = 0.0
      @subtotal = 0.0
      @shopify_products = []
      @orders = []
      @successful_orders = 0
      @failed_orders = 0
    end

    def perform
      @team.init

      puts "Preparing to generate #{@num_orders} for #{@type} #{@team.name}".yellow
      
      # Pre generate all the orders we want to push to shopify
      puts "Generating Orders...".yellow
      @num_orders.times do 
        begin
          @orders << generate_order
        rescue => e
          @failed_orders += 1
          @job.log_error("Issue making order: #{e}")
        end
      end

      puts "Attempting to save orders...".yellow

      saved_orders = ""
      @orders.each do |shopify_order|
        result = ShopifyAPIRetry.retry(5) { shopify_order.save }
        
        if result.present? && shopify_order.id.present?
          puts "Order saved".green
          @successful_orders += 1
          @job.update(num_of_records_processed: @successful_orders)
          saved_orders << "#{shopify_order.id},"
        else
          puts "Issue Saving Order".red
          puts "#{shopify_order.message}".red

          @failed_orders += 1

          @job.update(num_of_errors: @failed_orders)
          @job.log_error(shopify_order.message.to_s)
        end
        @job.update(num_of_records_not_processed: @num_orders - @successful_orders - @failed_orders)

        # Mitigate rate limit issues
        # This assumes that the orders are being generated in development stores
        # which have a different rate limit for order creation than live stores
        # (5 per minute vs 2 per second)
        
        # While, based on the rate limit given from shopify, 12 seconds should work
        # between each order saved, through trial and error this was the smallest interval
        # that consistently did not run into any rate limit issues
        sleep 13.5
      end

      @job.update(option_10: saved_orders)
    end

    def generate_order()

      # puts "generating order".magenta

      shopify_order = ShopifyAPI::Order.new(order_params)
      shopify_order.line_items = []
      shopify_order.shipping_lines = []

      # puts  "generating line items".magenta

      shopify_order = generate_line_items(shopify_order, @num_line_items)

      # puts "building shipping address".magenta
      shopify_order.shipping_address = build_shipping_address
      
      shopify_order.total_price = @total
      shopify_order.subtotal_price = @subtotal
      
      # puts "order generated".green

      return shopify_order
    end

    def order_params
      email = Faker::Internet.free_email
      order_hash = {
        email: email,
        customer: {
          "first_name": "#{Faker::Name.first_name}",
          "last_name": "#{Faker::Name.last_name}",
          "email": email
        },
        inventory_behaviour: 'decrement_obeying_policy',
        tags: 'hingeto',
        financial_status: 'paid'
      }

      order_hash
    end

    def generate_line_items(shopify_order, num_items)
      num_items.times do

        local_product = @team.product_listings[rand(@team.product_listings.count)].product

        product = ShopifyAPIRetry.retry(5) { ShopifyAPI::Product.find(local_product.shopify_identifier) }
        variant = product.variants[rand(product.variants.count)]

        local_variant = find_local_variant(variant)


        raise "Could not find local TeamUp Product" if local_variant.nil?

        @total += line_item_cost(local_variant, 1)
        @subtotal += line_item_cost(local_variant, 1)

        shopify_line_item = ShopifyAPI::LineItem.new(
          line_item_params(product, variant, local_variant, 1)
        )
        shipping_line_item = ShopifyAPI::ShippingLine.new(
          shipping_line_item_params(product, variant)
        )
        shopify_order.line_items << shopify_line_item
        shopify_order.shipping_lines << shipping_line_item
      end
      shopify_order
    end

    def find_local_variant(shopify_variant)
      local_variant = Spree::Variant.find_by(platform_supplier_sku: shopify_variant.sku)
      local_variant = Spree::Variant.find_by(original_supplier_sku: shopify_variant.sku) if local_variant.nil?
      local_variant
    end

    def line_item_params(product, shopify_variant, local_variant, quantity)
      {
          variant_id: shopify_variant.id,
          title: product.title,
          quantity: quantity,
          product_id: shopify_variant.product_id,
          name: shopify_variant.title,
          price: master_cost(local_variant)
      }
    end

    def shipping_line_item_params(line_item, shopify_variant)
      {
          code: 'Shipping',
          price: 3.0, # Is it okay if we just use a set value?
          source: 'Hingeto',
          title: 'Shipping',
          variant_id: shopify_variant.id
      }
    end

    def line_item_cost(variant, quantity)
      master_cost(variant) * quantity
    end

    def master_cost(variant)
      variant.master_cost || variant.cost_price
    end

    def build_shipping_address
      {
        address1: Faker::Address.street_address,
        address2: Faker::Address.street_address,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        country: "United States",
        phone: "999-999-9999",
        company: "Test Order Inc",
        zip: "90201",
        province: "California",
        city: "Oakland",
        country_code: "US",
        default: true
      }
    end
  end
end
