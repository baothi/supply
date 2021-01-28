class StripeCustomer < ApplicationRecord
  include InternalIdentifiable

  belongs_to :strippable, polymorphic: true
  has_one :stripe_subscription, dependent: :destroy
  has_one :stripe_plan, through: :stripe_subscription
  has_many :stripe_invoices, dependent: :destroy
  has_many :stripe_cards, dependent: :destroy

  # validates :strippable, presence: true, uniqueness: true
  validates :customer_identifier, presence: true, uniqueness: true

  def default_card
    default = stripe_cards.where(card_identifier: default_source).first
    default.present? ? default : stripe_cards.last
  end
end
