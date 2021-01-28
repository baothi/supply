class Spree::StockItemTracking < ApplicationRecord

  scope :for_retailer, ->(retailer_id) do
    joins(:product_listings)
    .merge(Spree::ProductListing.where(retailer_id: retailer_id))
  end

  scope :updated_since, ->(date) do
    where("spree_stock_item_trackings.updated_at >= ?", date)
  end

  scope :outstock_for_since, ->(retailer_id, date) do
    for_retailer(retailer_id)
    .updated_since(date)
    .state_outstock
  end

  scope :instock_for_since, ->(retailer_id, date) do
    for_retailer(retailer_id)
    .updated_since(date)
    .state_instock
  end

  enum state: {
    outstock: 'outstock',
    instock: 'instock'
  }, _prefix: 'state'

  belongs_to :stock_item
  belongs_to :product

  has_many :product_listings, through: :product
end
