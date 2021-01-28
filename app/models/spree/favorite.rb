class Spree::Favorite < ApplicationRecord
  belongs_to :retailer
  belongs_to :product

  validates :product_id, uniqueness: { scope: :retailer_id }
end
