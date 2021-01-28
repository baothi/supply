class StripePaymentMailer < ApplicationMailer
  default from: "Hingeto Dropship Support <#{ENV['RETAILER_EMAIL']}>"

  def invoice_payment_receipt(invoice)
    @invoice = invoice
    @strippable = @invoice.stripe_customer.strippable

    mail to: @strippable.email,
         subject: 'Payment receipt for subscription charge'
  end

  def invoice_failure(invoice)
    @invoice = invoice
    @strippable = @invoice.stripe_customer.strippable

    mail to: @strippable.email,
         subject: 'Card Payment Failure'
  end
end
