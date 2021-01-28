class Spree::MappedShippingMethod < ApplicationRecord
  # The owner of the credential
  belongs_to :teamable, polymorphic: true
  belongs_to :shipping_method

  validates_presence_of :teamable
  validates_presence_of :shipping_method
  validates_presence_of :value

  # validates :shipping_method, uniqueness: { scope: :shipping_method }
end
