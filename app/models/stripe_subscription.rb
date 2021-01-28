class StripeSubscription < ApplicationRecord
  include InternalIdentifiable

  belongs_to :stripe_customer
  belongs_to :stripe_plan
  has_many :stripe_events, as: :stripe_eventable

  validates :subscription_identifier, uniqueness: true
  validates :subscription_identifier, :customer_identifier, :stripe_customer, :stripe_plan,
            :status, :plan_identifier, :subscription_identifier, presence: true
end
