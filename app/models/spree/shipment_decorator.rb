Spree::Shipment.class_eval do
  def remove_shipping_cost!
    self.per_item_cost = 0
    self.save!
  end

  def set_cancellation_date_and_cancel!
    self.state = 'canceled'
    self.cancelled_at ||= DateTime.now
    self.save!
  end

  # Consolidate the above two methods
  def mark_as_cancelled!
    self.per_item_cost = 0
    self.state = 'canceled'
    self.cancelled_at ||= DateTime.now
    self.save!
  end

  def shipped_or_cancelled?
    return true if self.state == 'canceled' || self.state == 'shipped'

    false
  end
end
