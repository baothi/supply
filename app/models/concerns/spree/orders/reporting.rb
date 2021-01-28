module Spree::Orders::Reporting
  extend ActiveSupport::Concern

  class_methods do
    def generate_performance_report!
      job = Spree::LongRunningJob.create(
        action_type: 'export',
        job_type: 'orders_export',
        initiated_by: 'system'
      )
      Reports::OrdersPerformanceReportJob.perform_now(job.internal_identifier)
    end

    def num_of_paid_orders
      'TBD'
    end

    def revenue_to_date
      Spree::Order.sum(:total).to_f
    end

    def number_of_line_items
      Spree::LineItem.count
    end

    def total_quantity_of_line_items
      'TBD'
    end

    def ebay_query
      "customer_email iLIKE '%ebay%'"
    end

    def num_ebay_orders
      Spree::Order.where(ebay_query).count
    end

    def ebay_revenue
      Spree::Order.where(ebay_query).sum(:total).to_f
    end

    def amazon_query
      "customer_email iLIKE '%amazon%'"
    end

    def num_amazon_orders
      Spree::Order.where(amazon_query).count
    end

    def amazon_revenue
      Spree::Order.where(amazon_query).sum(:total).to_f
    end

    def number_of_orders
      Spree::Order.count
    end

    def num_of_orders_awaiting_payment
      'TBD'
    end
  end

  included do
  end
end
