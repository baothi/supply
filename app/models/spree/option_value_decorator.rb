Spree::OptionValue.class_eval do
  # To minimize locking issues we were experiencing

  private

  def touch_all_variants
    # Do nothing
  end
end
