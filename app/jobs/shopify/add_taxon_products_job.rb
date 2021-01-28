# frozen_string_literal: true

module Shopify
  class AddTaxonProductsJob < ApplicationJob
    queue_as 'shopify_export'

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?
      products = Spree::Taxon.find_by(id: job.option_1).products
      retailer = Spree::Retailer.find_by(id: job.retailer_id)
      job.update(total_num_of_records: products.count)

      begin
        message = Shopify::Product::BulkExporter.new(
          local_products: products,
          retailer: retailer
        ).perform
        ShopifyMailer.add_taxon_products_to_shopify(message, retailer).deliver_now if message
        job.complete_job!
      rescue => error
        job.log_error(error.to_s)
        job.raise_issue!
        return
      end
    end
  end
end
