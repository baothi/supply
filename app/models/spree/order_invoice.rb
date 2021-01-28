class Spree::OrderInvoice < ApplicationRecord
  belongs_to :order
  belongs_to :retailer
end
