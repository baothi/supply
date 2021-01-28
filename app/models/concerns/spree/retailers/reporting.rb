module Spree::Retailers::Reporting
  extend ActiveSupport::Concern

  class_methods do
    def generate_performance_report!
      job = Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'orders_export',
        initiated_by: 'system'
      )
      Reports::RetailersPerformanceReportJob.perform_now(job.internal_identifier)
    end
  end

  included do
  end

  def number_of_orders
    orders.count
  end

  def num_of_orders_awaiting_payment
    'TBD'
  end

  def date_of_install
    created_at.strftime('%D') unless created_at.nil?
  end

  def avg_num_of_days_to_first_order
    return 0 if orders.count.zero?

    first_order_created_at = orders.order('created_at asc').first.created_at
    num_days = (first_order_created_at - self.created_at) / 86400
    num_days.to_f
  end

  def avg_num_of_days_to_first_order_at_shopify
    return 0 if orders.count.zero?

    first_order_completed_at_shopify_at = orders.order('completed_at asc').first.completed_at
    return 0 if first_order_completed_at_shopify_at.nil?

    num_days = (first_order_completed_at_shopify_at - self.created_at) / 86400
    num_days.to_f
  end

  def revenue_to_date
    orders.sum(:total).to_f
  end

  def average_number_of_line_items
    # @tasks = @project.tasks.joins(:hours).select("tasks.*, sum(hours) as total")
    # #num_line_items = 0
    # num_orders = 0
    #
    # orders.line_items
  end

  # TODO
  def revenue_from_shopify_store
    0
  end

  def has_product?
    self.product_listings.count.positive?
  end

  def num_live_products
    self.product_listings.count
  end

  def ebay_query
    "customer_email iLIKE '%ebay%'"
  end

  def num_ebay_orders
    orders.where(ebay_query).count
  end

  def ebay_revenue
    orders.where(ebay_query).sum(:total).to_f
  end

  def amazon_query
    "customer_email iLIKE '%amazon%'"
  end

  def num_amazon_orders
    orders.where(amazon_query).count
  end

  def amazon_revenue
    orders.where(amazon_query).sum(:total).to_f
  end
end
