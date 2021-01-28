class Pricing::FixSupplierPriceJob < ApplicationJob
  queue_as :default
  include Shopify::Helpers

  def perform(job_id)
    @job = Spree::LongRunningjob.find_by(internal_identifier: job_id)
    @job.initialize_and_begin_job! unless @job.in_progress?

    @supplier = Spree::Supplier.find_by(id: @job.supplier_id)
    @supplier_variants = @supplier.variants
    return unless @supplier.init

    @job.update(total_num_of_records: supplier_variants.count)

    shopify_variants = ShopifyAPI::Variant.find(:all, params: { limit: 250 })

    process_variants(shopify_variants)

    while shopify_variants.next_page?
      shopify_variants = shopify_variants.fetch_next_page
      process_variants(shopify_variants)
    end

    @job.complete_job! if @job.may_complete_job?
  end

  def process_variants(shopify_variants)
    shopify_variants.each do |shopify_variant|
      local_variant = @supplier_variants.find_by(shopify_identifier: shopify_variant.id)
      next unless local_variant.present?

      status = local_variant.update_attributes(
        msrp_price: return_msrp_price(shopify_variant, @supplier),
        cost_price: set_basic_cost(shopify_variant.price.to_f, @supplier),
        price: price(shopify_variant.price, @supplier)
      )
      @job.update_status(status)
    end
    sleep 1 if (page % 5).zero?
  end
end
