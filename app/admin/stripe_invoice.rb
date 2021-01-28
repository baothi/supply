ActiveAdmin.register StripeInvoice do
  menu label: 'Invoice', parent: 'Stripe'

  form do |_t|
    inputs do
      input :closed
      input :currency
      input :date
      input :description
      input :forgiven
      input :period_start
      input :period_end
      input :receipt_number
    end
  end
end
