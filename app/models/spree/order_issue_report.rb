class Spree::OrderIssueReport < ApplicationRecord
  include AASM
  include IntervalSearchScopes

  belongs_to :order, class_name: 'Spree::Order'
  has_one :retailer, through: :order

  has_attached_file :image1
  has_attached_file :image2

  after_create :notify_supplier_admin_and_retailer

  validates :description, presence: true
  validates_attachment_content_type :image1, content_type: /\Aimage\/.*\z/
  validates_attachment_content_type :image2, content_type: /\Aimage\/.*\z/

  aasm column: :resolution do
    state :pending, initial: true
    state :resolved_supplier, :resolved_hingeto, :declined

    event :resolve_as_supplier do
      transitions from: :pending, to: :resolved_supplier, after: :issue_resolved,
                  if: :supplier_allows_issue_reporting
    end

    event :resolve_as_hingeto do
      transitions from: :pending, to: :resolved_hingeto, after: :issue_resolved
    end

    event :decline do
      transitions from: :pending, to: :declined, after: :issue_resolved
    end

    # event :switch_owner do
    #   transitions from: :resolved_supplier, to: :resolved_hingeto
    #   transitions from: :resolved_hingeto, to: :resolved_supplier
    # end
  end

  def supplier_allows_issue_reporting
    order.supplier.allow_order_issue_reporting
  end

  def issue_resolved
    event = aasm.current_event
    credit = retailer.retailer_credit || retailer.build_retailer_credit
    credit.increment(:by_supplier, amount_credited).save if event == :resolve_as_supplier!
    credit.increment(:by_hingeto, amount_credited).save if event == :resolve_as_hingeto!

    OrdersMailer.issue_resolved(id).deliver_later if id
  end

  def resolved?
    resolved_supplier? || resolved_hingeto? || declined?
  end

  def notify_supplier_admin_and_retailer
    OrdersMailer.issue_reported(id).deliver_later
    OrdersMailer.report_received(id).deliver_later
  end

  def summary
    description[0..50]
  end
end
