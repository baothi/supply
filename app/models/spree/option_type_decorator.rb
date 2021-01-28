Spree::OptionType.class_eval do
  # To minimize locking issues we were experiencing

  private

  def touch_all_products
    # Do nothing
  end
end
