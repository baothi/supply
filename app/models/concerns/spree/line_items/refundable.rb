module Spree::LineItems::Refundable
  extend ActiveSupport::Concern

  included do
  end

  def issue_full_refund!(allow_fulfilled_orders: false,
                         reason: 'N/A')
    ro = ResponseObject.new
    ro.reset_message!

    begin
      if !allow_fulfilled_orders && (self.fulfilled_at.present? || self.shipped?)
        ro.message = 'Cannot work with fulfilled line items / orders.'
        ro.success = false
        return ro
      end
      # Look for Stripe Payments
      stripe_payments = order.eligible_stripe_payments
      payment = stripe_payments.first

      raise 'No stripe payments were found or order is fully refunded' if payment.nil?

      amount = self.line_item_cost_with_shipping

      response = refund_stripe_payment!(payment: payment, amount: amount)
      if response[:success]
        self.mark_as_fully_refunded!

        Spree::RefundRecord.create(
          refund_id: response[:refund_id],
          refund_type: 'line_item',
          log: reason,
          is_partial: true
        )
        msg = I18n.t('orders.refunds.successful',
                     number: payment.number,
                     amount: amount.to_f)
        notify_retailer_of_refund
        ro.success = true
      else
        msg = I18n.t('orders.refunds.error',
                     number: payment.number,
                     error: response[:error])
        ro.success = false
      end
      order.update_shopify_logs(msg)
      ro.message << msg
    rescue => ex
      ro.success = false
      ro.message = "#{ex}"
      puts "#{ex}".red
      order.update_shopify_logs(ex)
    end
    ro
  end

  def notify_retailer_of_refund
    OrdersMailer.partially_refunded_order(self.retailer_id, self.id).deliver_later
  end

  def mark_as_fully_refunded!
    self.refunded_total_at = DateTime.now
    self.save!
  end

  def mark_as_fully_refunded_shipping!
    self.refunded_shipping_at = DateTime.now
    self.save!
  end

  def refund_stripe_payment!(payment:, amount:)
    response = StripeService.refund_partial_charge(
      stripe_charge_id: payment.number,
      amount: amount,
      refund_reason_id: Spree::RefundReason.first.id,
      payment_id: payment.id
    )
    response
  end
end
