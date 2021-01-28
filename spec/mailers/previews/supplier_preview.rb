# Preview all emails at http://localhost:3000/rails/mailers/vendor
class SupplierPreview < ActionMailer::Preview
  def welcome
    SupplierMailer.welcome(Spree::Supplier.last.id)
  end

  def invite_retailers
    SupplierMailer.invite_retailers(Spree::Supplier.last.id)
  end
end
