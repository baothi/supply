class ProductsMailer < ApplicationMailer
  default from: "TeamUp Support <#{ENV['SUPPLIER_EMAIL']}>"
  layout 'admin/mailer'

  def products_removed_from_shopify(retailer_id, product_ids)
    @retailer = Spree::Retailer.find_by(id: retailer_id)
    @products = Spree::Product.where(id: product_ids)

    mail to: @retailer.email, subject: ' Invalid Products Found'
  end

  def products_csv_download(job, file)
    @job = job
    attachments[job.output_csv_file_file_name] = file
    mail to: ENV['OPERATIONS_EMAIL'], subject: "Product CSV download- #{DateTime.now}"
  end
end
