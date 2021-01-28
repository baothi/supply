class Spree::Courier < ApplicationRecord
  has_many :shipping_methods
  has_many :shipments
end
