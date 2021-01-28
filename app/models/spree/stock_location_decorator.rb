Spree::StockLocation.class_eval do
  after_create :set_backorderable_default
  def set_backorderable_default
    self.update(backorderable_default: true) unless self.backorderable_default
  end
end
