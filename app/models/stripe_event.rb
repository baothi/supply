class StripeEvent < ApplicationRecord
  include InternalIdentifiable

  # serialize :event_object, HashSerializer

  belongs_to :stripe_eventable, polymorphic: true

  validates :event_identifier, :stripe_eventable, presence: true
  validates :event_identifier, uniqueness: true

  def event_object
    (super || {}).with_indifferent_access
  end
end
