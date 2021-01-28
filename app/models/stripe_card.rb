class StripeCard < ApplicationRecord
  include InternalIdentifiable

  belongs_to :stripe_customer

  validates :card_identifier, uniqueness: true
  validates :card_identifier, :stripe_customer, :customer_identifier, :exp_month, :exp_year, :last4,
            presence: true

  def exp_date
    "#{exp_month}/#{exp_year}"
  end

  def last_four
    "XXXX-XXXX-XXXX-#{last4}"
  end

  def last_four_fancy
    "**** **** ***** #{last4}"
  end

  def default?
    card_identifier == stripe_customer.default_source
  end

  def icon_css_class
    return 'fa-cc-amex' if brand.include? 'American'

    "fa-cc-#{brand.downcase}"
  end

  def imported
    nil
  end

  def has_payment_profile?
    stripe_customer.present?
  end
end
