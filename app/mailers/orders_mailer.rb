class OrdersMailer < ApplicationMailer
  default from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>"
  layout 'admin/mailer'

  # File Keys -
  # file[:name]
  # file[:content]

  def remittance_issue(order, message)
    @message = message
    @order = order
    @retailer_link = "#{ENV['SITE_URL']}/active/admin/#{order.try(:retailer).try(:slug)}"

    # attachments[file[:name]] = file[:content] unless file.blank? || file[:content].empty?

    attachments['logs.txt'] = order.shopify_logs.to_s

    mail to: ENV['OPERATIONS_EMAIL'],
         subject: "[Urgent] TeamUp Remittance Issue for #{order.internal_identifier}"
  end

  def issue_reported(report_id)
    @report = Spree::OrderIssueReport.find_by(id: report_id)
    @retailer = @report.retailer
    @order = @report.order

    mail to: ENV['OPERATIONS_EMAIL'], subject: 'New order issue reporting'
  end

  def report_received(report_id)
    @report = Spree::OrderIssueReport.find_by(id: report_id)
    @retailer = @report.retailer
    @order = @report.order

    mail to: @retailer.email, subject: 'Issue report received'
  end

  def issue_resolved(report_id)
    @report = Spree::OrderIssueReport.find_by(id: report_id)
    @retailer = @report.retailer
    @order = @report.order

    mail to: @retailer.email, subject: 'Order issue report resolution'
  end

  def auto_paid_orders(retailer_id, order_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @orders = Spree::Order.where(id: order_ids)
    return unless @retailer.present? && @orders.present?

    @orders.update_all(auto_paid_retailer_notified_at: Time.current)
    mail(to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: "#{@orders.count} new auto-paid order(s)",
         bcc: ENV['OPERATIONS_EMAIL']) do |format|
      format.html { render layout: 'mailer' }
      format.text
    end
  end

  # TODO: Add the ability to specify if something will ship or not.
  def fully_refunded_order(retailer_id, order_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @orders = Spree::Order.where(id: order_ids)
    return unless @retailer.present? && @orders.present?

    mail(to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: I18n.t('orders.refunds.email',
                         order_name: @orders.first.retailer_shopify_name)) do |format|
      format.html { render layout: 'mailer' }
      format.text
    end
  end

  def partially_refunded_order(retailer_id, line_item_id)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @line_item = Spree::LineItem.find_by(id: line_item_id)
    return unless @line_item.present?

    @order = @line_item.order
    return unless @retailer.present? && @order.present?

    mail(to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: I18n.t('orders.refunds.partial_refund',
                         order_name: @order.retailer_shopify_name)) do |format|
      format.html { render layout: 'mailer' }
      format.text
    end
  end

  def fully_cancelled_order(retailer_id, order_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @orders = Spree::Order.where(id: order_ids)
    return unless @orders.present?
    return unless @retailer.present?

    mail(to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: I18n.t('orders.cancel.full_cancellation_email',
                         order_name: @orders.first.retailer_shopify_name)) do |format|
      format.html { render layout: 'mailer' }
      format.text
    end
  end

  # We assume all the line items belong to the same order
  def partially_cancelled_order(retailer_id, line_items_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    return unless @retailer.present?

    @line_items = Spree::LineItem.where(id: line_items_ids)
    return unless @line_items.present?

    @order = @line_items.first.order
    mail(to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: I18n.t('orders.cancel.partial_cancellation_email',
                         order_name: @order.retailer_shopify_name)) do |format|
      format.html { render layout: 'mailer' }
      format.text
    end
  end

  def stale_orders_refunded(retailer_id, order_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @orders = Spree::Order.where(id: order_ids)
    return if @retailer.blank? || @orders.blank?

    mail to: @retailer.email,
         from: ENV['RETAILER_EMAIL'],
         subject: 'Stale Orders Refund'
  end
end
