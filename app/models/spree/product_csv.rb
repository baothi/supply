module Spree
  class ProductCsv < ApplicationRecord
    def self.start_job(ransack_query, user_id)
      long_job = Spree::LongRunningJob.create!(
        action_type: 'export',
        job_type: 'csv_export',
        initiated_by: 'user',
        user_id: user_id,
        option_1: ransack_query.try(:to_json) || '{}',
        option_2: 'Spree::ProductCSVJob'
      )
      ::Products::ExportAsCsvJob.perform_later(long_job.internal_identifier)
    end

    def self.headers
      display_fields.values
    end

    def self.body
      display_fields.keys
    end

    def self.display_fields
      {
        supplier: 'Supplier',
        product_title: 'Product Title',
        description: 'Description',
        shopify_vendor: 'Shopify Vendor',
        supplier_brand_name: 'Supplier Brand Name',
        vendor_style_identifier: 'Handle-MPN',
        sku: 'SKU',
        original_supplier_sku: 'Original Supplier SKU',
        barcode: 'Barcode',
        gtin: 'GTIN',
        weight: 'Weight',
        weight_unit: 'Weight Unit',
        height: 'Height',
        supplier_color: 'Supplier Color',
        hingeto_color: 'Hingeto Color',
        supplier_size: 'Supplier Size',
        hingeto_size: 'Hingeto Size',
        supplier_category: 'Supplier Category',
        hingeto_category: 'Hingeto Category',
        variant_image: 'Variant Image',
        product_image: 'Product Image',
        wholesale_cost: 'Wholesale Cost',
        cost_currency: 'Cost Currency',
        msrp_price: 'MSRP Price',
        msrp_currency: 'MSRP Currency',
        map_price: 'MAP Price',
        submission_state: 'Approved'
      }
    end

    def self.custom_ransack(query = {})
      ransack_map = {
        'name_contains' => 'product_title_cont',
        'name_equals' => 'product_title_eq',
        'name_starts_with' => 'product_title_start',
        'name_ends_with' => 'product_title_end'
      }
      ransack_map.each do |key, value|
        query[value] = query.delete(key) if query.has_key?(key)
      end
      ransack(query)
    end
  end
end
