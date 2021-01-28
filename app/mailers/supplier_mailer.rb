class SupplierMailer < ApplicationMailer
  def welcome(supplier_id)
    @supplier = Spree::Supplier.find(supplier_id)

    mail to: @supplier.email, subject: 'Welcome to TeamUp'
  end

  def invite_retailers(supplier_id)
    @supplier = Spree::Supplier.find(supplier_id)

    mail to: @supplier.email, subject: 'Invite retailers to move up in priority'
  end

end
