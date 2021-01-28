class Spree::OrderRisk < ApplicationRecord
  belongs_to :order, class_name: 'Spree::Order'
end
