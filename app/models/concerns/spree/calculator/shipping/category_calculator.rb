module Spree
  class Calculator::Shipping::CategoryCalculator < Spree::ShippingCalculator
    preference :first_item_us,     :decimal, default: 5.0
    preference :additional_item_us, :decimal, default: 2.0

    preference :first_item_canada,     :decimal, default: 5.0
    preference :additional_item_canada, :decimal, default: 2.0

    preference :first_item_rest_of_world,    :decimal, default: 10.0
    preference :additional_item_rest_of_world, :decimal, default: 5.0

    # After Commit
    include CommitWrap

    after_save_commit :update_shopify_metafields, on: :update, if: proc { preferences_changed? }

    def self.description
      # Human readable description of the calculator
      'Supply Calculator'
    end

    def compute_package(package)
      # Returns the value after performing the required calculation
      # content contains content_items
      puts 'called compute_package'.magenta
      puts "order: #{package.order.nil?}"
      puts "order contents: #{package.order.inspect}"
      puts "num_contents: #{package.contents.count}"

      package.contents.each do |content_item|
        puts "#{content_item.inspect}".yellow
        inventory_unit = content_item.inventory_unit

        shipment = inventory_unit.shipment
        puts 'shipment is null' if shipment.nil?
        next if shipment.nil?

        puts "Price for shipment: #{shipment.cost}".green
      end
      puts '------'.yellow

      # First step is to find the lowest cost item in entire cart

      calculate_shipping_cost(package)
    end

    def calculate_shipping_cost(package)
      content_item = package.contents[0]
      inventory_unit = content_item.inventory_unit
      variant = inventory_unit.variant
      product = variant.product
      shipping_category = product.shipping_category
      if shipping_category.present? && !shipping_category.shipping_methods.empty?
        calculator = shipping_category.shipping_methods[0].calculator

        return 0 if calculator.nil?

        order = package.order
        per_additional = if order.us_order?
                           calculator.preferences[:additional_item_us]
                         elsif order.canada_order?
                           calculator.preferences[:additional_item_canada]
                         else
                           calculator.preferences[:additional_item_rest_of_world]
                         end

        per_additional = set_to_non_zero(per_additional)
        per_additional
      else
        2
      end
    end

    def set_to_non_zero(val, default = 2)
      return default if val.nil? || val.zero?

      val
    end

    def lowest_cost_item(package)
      package.contents.each do |content_item|
        inventory_unit = content_item.inventory_unit
        variant = inventory_unit.variant
        product = variant.product
        shipping_category = product.shipping_category
        if shipping_category.present? && !shipping_category.shipping_methods.empty?
          calculator = shipping_category.shipping_methods[0].calculator
          # first_item = calculator.preferences[:first_item]

          order = package.order
          if order.us_order?
            per_additional = calculator.preferences[:additional_item_us]
            per_additional ||= 2
          elsif order.canada_order?
            per_additional = calculator.preferences[:additional_item_canada]
            per_additional ||= 1
          else
            per_additional = calculator.preferences[:additional_item_rest_of_world]
            per_additional ||= 2
          end

          per_additional
        end
      end
    end

    def update_shopify_metafields
      return unless calculable.is_a? Spree::ShippingMethod

      ActiveRecord::Base.transaction do
        job = create_product_metafield_update_job
        execute_after_commit do
          Shopify::ProductMetafieldsUpdateWorker.perform_async(job.internal_identifier)
        end
      end
    end

    def create_product_metafield_update_job
      Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'products_export',
        initiated_by: 'system',
        option_1: id
      )
    end
  end
end
