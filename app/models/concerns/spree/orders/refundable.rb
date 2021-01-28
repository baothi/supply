module Spree::Orders::Refundable
  extend ActiveSupport::Concern

  included do
  end

  def issue_refund_for_line_item!(allow_fulfilled_line_item: false); end

  def issue_full_refund!(allow_fulfilled_orders: false, reason: 'N/A', in_credit: false)
    ro = ResponseObject.new
    ro.reset_message!

    begin
      unless allow_fulfilled_orders
        ro.message = 'Cannot work with fulfilled orders.'
        ro.success = false
        return ro
      end

      # Look for Stripe Payments
      stripe_payments = completed_stripe_payments
      payment = stripe_payments.first

      raise 'No stripe payments were found or order is partially/fully refunded' if payment.nil?

      response = in_credit ? issue_credit_refund!(payment) : refund_stripe_payment!(payment)
      if response[:success]
        self.refund_credit_discount!
        self.mark_as_fully_refunded!

        Spree::RefundRecord.create(
          refund_id: response[:refund_id],
          refund_type: 'order',
          log: reason,
          is_partial: false
        )
        msg = I18n.t('orders.refunds.successful',
                     number: payment.number,
                     amount: payment.amount.to_f)
        notify_retailer_of_refund
        ro.success = true
      else
        msg = I18n.t('orders.refunds.error',
                     number: payment.number,
                     error: response[:error])
        ro.success = false
      end
      self.update_shopify_logs(msg)
      ro.message << msg
    rescue => ex
      ro.success = false
      ro.message = "#{ex}"
      puts "#{ex}".red
      self.update_shopify_logs(ex)
    end
    ro
  end

  def has_refunds?
    return true if payments.where(state: ['refunded', 'partially_refunded']).count.positive?
    return true if self.fully_refunded_shipping_at || self.fully_refunded_total_at

    payment_ids = payments.pluck(:id)
    Spree::Refund.where(payment_id: payment_ids).count.positive?
  end

  def notify_retailer_of_refund
    OrdersMailer.fully_refunded_order(self.retailer_id, [self.id]).deliver_later
  end

  def mark_as_fully_refunded!
    ActiveRecord::Base.transaction do
      self.fully_refunded_total_at = DateTime.now
      self.save!
      line_items.each(&:mark_as_fully_refunded!)
    end
  end

  def mark_as_fully_refunded_shipping!
    self.fully_refunded_shipping_at = DateTime.now
    self.save!
  end

  def refund_stripe_payment!(payment)
    response = StripeService.refund_charge(
      stripe_charge_id: payment.number,
      amount: payment.amount,
      refund_reason_id: Spree::RefundReason.first.id,
      payment_id: payment.id
    )
    response
  end

  def issue_credit_refund!(payment)
    retailer = self.retailer
    credit = retailer.retailer_credit || retailer.build_retailer_credit

    spree_refund = nil
    ActiveRecord::Base.transaction do
      credit.increment(:by_hingeto, payment.amount).save

      spree_refund = Spree::Refund.create!(
        payment_id: payment.id, refund_reason_id: Spree::RefundReason.first.id,
        amount: payment.amount, transaction_id: nil
      )

      payment.refund!
    end

    if spree_refund.present? && spree_refund.persisted?
      { error: nil, success: 'Refund successfully', refund_id: spree_refund.id }
    else
      { error: 'Error issuing credit', success: nil, refund_id: nil }
    end
  end

  def refund_credit_discount!
    retailer = self.retailer
    credit = retailer.retailer_credit || retailer.build_retailer_credit
    credit.increment(:by_hingeto, self.hingeto_discount)
    credit.increment(:by_supplier, self.supplier_discount)
    credit.save
  end
end
