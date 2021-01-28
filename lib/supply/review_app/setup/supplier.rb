require_relative './base'

module Supply
  module ReviewApp
    module Setup
      class Supplier < Base
        def run
          supplier = create_supplier

          download_supplier_products(supplier)
          refresh_product_categories(supplier)
          set_product_pricing(supplier)
          set_product_size_and_color(supplier)
          map_supplier_color_option_to_platforms(supplier)
          refresh_product_color(supplier)
          map_supplier_size_option_to_platforms(supplier)
          refresh_product_size(supplier)
          update_product_names_with_heroku_app_name(supplier)
          check_for_eligibility_and_approve(supplier)

          Spree::Product.reindex!
        end

        def create_supplier
          shop = ENV['PR_SHOPIFY_STORE_SHOP_URL_SUPPLIER']
          supplier = create_teamable(Spree::Supplier, shop)

          supplier.shopify_url = supplier.domain = shop
          supplier.name = ENV['PR_SHOPIFY_STORE_NAME_SUPPLIER']
          supplier.shop_owner = "#{ENV['PR_SHOPIFY_STORE_NAME_SUPPLIER']} Admin"
          supplier.instance_type = 'ecommerce'
          supplier.shopify_product_unique_identifier = 'sku'
          supplier.save

          create_shopify_credentials(supplier, shop, ENV['PR_SHOPIFY_STORE_ACCESS_TOKEN_SUPPLIER'])
          set_us_shipping_zones(supplier)
          map_supplier_category_option_to_platforms(supplier)

          create_user(supplier)

          supplier
        end

        def check_for_eligibility_and_approve(supplier)
          supplier.products.each do |product|
            product.skip_middle_steps_and_approve! if product.reload.eligible_for_approval?
          end
        end

        def download_supplier_products(supplier)
          supplier.download_shopify_products_now!(true)
        end

        def set_us_shipping_zones(supplier)
          zone = Spree::Zone.find_or_create_by(name: 'United States') do |sz|
            sz.description = 'United States Only'
            sz.kind = 'country'
          end

          supplier.shipping_zones << zone unless supplier.shipping_zones.include? zone
          supplier.save
        end

        def map_supplier_category_option_to_platforms(supplier)
          supplier.supplier_category_options.update_all(
            platform_category_option_id: Spree::PlatformCategoryOption.first.id
          )
        end

        def map_supplier_color_option_to_platforms(supplier)
          supplier.supplier_color_options.each do |option|
            name = "#{option.name}-#{supplier.brand_short_code}"
            platform_color = Spree::PlatformColorOption.create(
              name: name, presentation: name.upcase
            )
            option.update(platform_color_option_id: platform_color.id)
          end
        end

        def map_supplier_size_option_to_platforms(supplier)
          supplier.supplier_size_options.each do |option|
            name = "#{option.name}-#{supplier.brand_short_code}"
            platform_size = Spree::PlatformSizeOption.create(
              name: name, presentation: name.upcase, name_1: name.upcase
            )
            option.update(platform_size_option_id: platform_size.id)
          end
        end

        def refresh_product_categories(supplier)
          job = create_updater_job(supplier)
          ::Category::CategorizeSupplierProductsJob.perform_now(job.internal_identifier)
          ::Category::MapSupplierProductsJob.perform_now(job.internal_identifier)
        end

        def refresh_product_color(supplier)
          job = create_updater_job(supplier)
          ::Color::UpdateSupplierProductsColorsJob.perform_now(job.internal_identifier)
          ::Color::MapSupplierProductsColorsJob.perform_now(job.internal_identifier)
        end

        def refresh_product_size(supplier)
          job = create_updater_job(supplier)
          ::Size::UpdateSupplierProductsSizesJob.perform_now(job.internal_identifier)
          ::Size::MapSupplierProductsSizesJob.perform_now(job.internal_identifier)
        end

        def create_updater_job(supplier)
          Spree::LongRunningJob.create(
            action_type: 'import',
            job_type: 'products_categorize',
            initiated_by: 'user',
            option_1: 'categorize',
            supplier_id: supplier.id
          )
        end

        def set_product_pricing(supplier)
          supplier.products.each do |product|
            product.variants.each do |variant|
              variant_cost = Spree::VariantCost.find_or_initialize_by(
                sku: variant.original_supplier_sku, supplier_id: supplier.id
              )
              variant_cost.minimum_advertised_price = 15.0
              variant_cost.msrp = 19.99
              variant_cost.cost = 10.0
              variant_cost.save
            end
          end
        end

        def set_product_size_and_color(supplier)
          supplier.products.each do |product|
            product.variants.each_with_index do |variant, i|
              set_color_values(variant, i)
              set_size_values(variant, i)
            end
          end
        end

        def update_product_names_with_heroku_app_name(supplier)
          source = Rails.env.development? ? local_app_name : Supply::ReviewApp::Helpers.app_number
          supplier.products.each do |product|
            product.update(name: "#{product.name} (#{source})")
          end
        end

        private

        def set_color_values(variant, index)
          color_name = Spree::PlatformColorOption.all[index].name.upcase
          variant.set_option_value('Color', color_name)

          ActiveRecord::Base.transaction do
            supplier_color_option = variant.create_supplier_color_option(color_name)

            variant.update_columns(
              supplier_color_value: color_name,
              supplier_color_option_id: supplier_color_option.id
            )
          end
        end

        def set_size_values(variant, index)
          size_name = Spree::PlatformSizeOption.all[index].name.upcase
          variant.set_option_value('Size', size_name)

          ActiveRecord::Base.transaction do
            supplier_size_option = variant.create_supplier_size_option(size_name)

            variant.update_columns(
              supplier_size_value: size_name,
              supplier_size_option_id: supplier_size_option.id
            )
          end
        end

        def local_app_name
          ENV['DEVELOPMENT_MACHINE_NAME'] || SecureRandom.hex(3).upcase
        end
      end
    end
  end
end
