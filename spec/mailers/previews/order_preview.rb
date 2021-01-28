# Preview all emails at http://localhost:3000/rails/mailers/stripe_payment
class OrderPreview < ActionMailer::Preview
  # Preview this email at http://localhost:7000/rails/mailers/admin_order/remittance_issue
  def remittance_issue
    OrdersMailer.remittance_issue(Spree::Order.last, 'Random Error')
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/issue_reported
  def issue_reported
    OrdersMailer.issue_reported(Spree::OrderIssueReport.last.id)
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/report_received
  def report_received
    OrdersMailer.report_received(Spree::OrderIssueReport.last.id)
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/issue_resolved
  def issue_resolved
    OrdersMailer.issue_resolved(Spree::OrderIssueReport.last.id)
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/auto_paid_orders
  def auto_paid_orders
    OrdersMailer.auto_paid_orders(Spree::Retailer.last.id, Spree::Order.last(3).map(&:id))
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/auto_paid_orders
  def fully_refunded_order
    OrdersMailer.fully_refunded_order(Spree::Retailer.last.id, Spree::Order.last(3).map(&:id))
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/auto_paid_orders
  def partially_refunded_order
    OrdersMailer.partially_refunded_order(Spree::Retailer.last.id, Spree::LineItem.last.id)
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/fully_cancelled_order
  def fully_cancelled_order
    OrdersMailer.fully_cancelled_order(Spree::Retailer.last.id, Spree::Order.last(3).map(&:id))
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/partially_cancelled_order
  def partially_cancelled_order
    OrdersMailer.partially_cancelled_order(Spree::Retailer.last.id, [Spree::LineItem.last.id])
  end

  # Preview this email at http://localhost:7000/rails/mailers/admin_order/stale_orders_refunded
  def stale_orders_refunded
    OrdersMailer.stale_orders_refunded(Spree::Retailer.last.id, Spree::Order.limit(3).ids)
  end
end
