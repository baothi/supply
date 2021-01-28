class StripeInvoice < ApplicationRecord
  include InternalIdentifiable

  # serialize :discount, HashSerializer

  after_save :send_invoice_payment_succeed, if: :paid_changed?
  after_save :send_invoice_failure_mail, if: :attempt_count_changed?

  belongs_to :stripe_customer
  has_many :stripe_events, as: :stripe_eventable

  validates :invoice_identifier, uniqueness: true
  validates :invoice_identifier, :stripe_customer, :charge_identifier, :customer_identifier,
            :subscription_identifier, :total, :amount_due, presence: true

  CENT_TO_DOLLAR_RATE = 100

  def subscription
    return unless subscription_identifier.present?

    StripeSubscription.find_by(subscription_identifier: subscription_identifier)
  end

  def discount
    (super || {}).with_indifferent_access
  end

  def total_in_dollars
    total / CENT_TO_DOLLAR_RATE
  end

  private

  def send_invoice_payment_succeed
    return unless paid

    StripePaymentMailer.invoice_payment_receipt(self).deliver_later
  end

  def send_invoice_failure_mail
    return if paid

    StripePaymentMailer.invoice_failure(self).deliver_later
  end
end
