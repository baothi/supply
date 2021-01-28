Spree::Stock::Quantifier.class_eval do
  # We do this because we always want to bring in ALL orders and then determine
  # programmatically via other services if we can supply it or not since
  # our internal inventory number (in postgres) isn't necessarily the source of truth
  def can_supply?(_required = 1)
    true
  end
end
