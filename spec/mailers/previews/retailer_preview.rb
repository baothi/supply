# Preview all emails at http://localhost:3000/rails/mailers/retailer
class RetailerPreview < ActionMailer::Preview
  def welcome
    RetailerMailer.welcome(Spree::Retailer.last.id)
  end

  def invite_vendors
    RetailerMailer.invite_vendors(Spree::Retailer.last.id)
  end
end
