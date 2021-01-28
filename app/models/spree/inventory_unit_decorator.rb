Spree::InventoryUnit.class_eval do
  scope :canceled, -> { where state: 'canceled' }

  state_machine initial: :on_hand do
    event :cancel do
      transition to: :on_hand, from: :canceled
    end
  end

  # Consolidate the above two methods
  def mark_as_cancelled!
    self.state = 'canceled'
    self.cancelled_at ||= DateTime.now
    self.save!
  end
end
