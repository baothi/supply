class ShopifyMailer < ApplicationMailer
  default from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>"
  layout 'admin/mailer'

  def add_taxon_products_to_shopify(message, retailer)
    @message = message
    mail to: retailer.email, subject: 'Bulk Product Export To Shopify'
  end
end
