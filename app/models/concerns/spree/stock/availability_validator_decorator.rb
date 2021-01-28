Spree::Stock::AvailabilityValidator.class_eval do
  private

  def item_available?(_line_item, _quantity)
    true
  end
end
