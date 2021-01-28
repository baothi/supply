# Preview all emails at http://localhost:3000/rails/mailers/stripe_payment
class StripePaymentPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/stripe_payment/invoice_payment_receipt
  def invoice_payment_receipt
    StripePaymentMailer.invoice_payment_receipt(StripeInvoice.last)
  end

  # Preview this email at http://localhost:3000/rails/mailers/stripe_payment/invoice_failure
  def invoice_failure
    StripePaymentMailer.invoice_failure(StripeInvoice.last)
  end
end
