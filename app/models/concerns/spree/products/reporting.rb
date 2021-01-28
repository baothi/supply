module Spree::Products::Reporting
  extend ActiveSupport::Concern

  class_methods do
    def generate_performance_report!
      job = Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'orders_export',
        initiated_by: 'system'
      )
      Reports::ProductsPerformanceReportJob.perform_now(job.internal_identifier)
    end
  end

  included do
  end

  def orders_for_product
    ids_for_variants = variants.map(&:id)
    line_items = Spree::LineItem.where('variant_id in (:variants)',
                                       variants: ids_for_variants)

    order_ids = line_items.map(&:order_id)
    order_ids.uniq!

    # puts "Orders: #{order_ids}".yellow

    Spree::Order.where('id in (:orders)', orders: order_ids)
  end

  def revenue_from_product
    orders_for_product.sum(:total)
  end

  def number_of_orders_with_product
    orders_for_product.count
  end

  def revenue_generated_for_retailers
    'TBD'
  end
end
