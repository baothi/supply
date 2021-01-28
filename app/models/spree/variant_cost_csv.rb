module Spree
  class VariantCostCsv < ApplicationRecord
    def self.start_job(ransack_query, user_id)
      long_job = Spree::LongRunningJob.create!(
        action_type: 'export',
        job_type: 'csv_export',
        initiated_by: 'user',
        user_id: user_id,
        option_1: ransack_query.try(:to_json) || '{}'
      )
      ::VariantCosts::ExportAsCsvWorker.perform_async(long_job.internal_identifier)
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
        msrp: 'MSRP Price',
        cost: 'Wholesale Cost',
        minimum_advertised_price: 'MAP Price'
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
