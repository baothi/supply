class StripePlan < ApplicationRecord
  include InternalIdentifiable

  has_many :stripe_subscriptions
  has_many :stripe_customers, through: :stripe_subscriptions
  has_many :stripe_events, as: :stripe_eventable

  validates :plan_identifier, :name, :amount, :currency, :interval, :interval_count, presence: true
  validates :plan_identifier, uniqueness: true

  scope :active, -> { where(active: true) }

  def current_for?(strippable)
    strippable.stripe_customer.try(:stripe_plan) == self
  end
end
