class Retailer::InvoicesController < Retailer::BaseController
  def index
    @invoices = current_retailer.stripe_customer.try(:stripe_invoices)
  end

  def orders
    @invoices = Spree::OrderInvoice.where(retailer_id: current_retailer.id)
  end
end
