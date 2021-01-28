module Spree::Orders::Cancelable
  extend ActiveSupport::Concern

  included do
    has_many :eligible_line_items, -> { where(cancelled_at: nil).order(:created_at) },
             inverse_of: :order, dependent: :destroy, class_name: 'Spree::LineItem'
    has_many :cancelled_line_items, -> { where.not(cancelled_at: nil).order(:created_at) },
             inverse_of: :order, dependent: :destroy, class_name: 'Spree::LineItem'
  end

  class_methods do
    def set_canceled_at_on_legacy_orders!
      Spree::Order.where(shipment_state: 'canceled', canceled_at: nil).find_each do |order|
        cancellation_date = order.cancelled_line_items.first&.cancelled_at
        order.canceled?
        order.canceled_at = cancellation_date || DateTime.now
        order.save!
      end
    end

    # We provide this alias to make it easy to find references of
    # *.line_items in the code base that may not be using the correct set of line items
    def all_line_items
      line_items
    end
  end

  # If line_items is empty, we assume full cancellation
  def notify_retailers_of_cancellation!(_role = 'supplier', line_items = [])
    if line_items.any?
      OrdersMailer.partially_cancelled_order(self.retailer_id, line_items).deliver_later
    else
      OrdersMailer.fully_cancelled_order(self.retailer_id, [self.id]).deliver_later
    end
  end

  def cancel_shipments_for_cancelled_line_items!
    self.cancelled_line_items.each(&:cancel_line_item_shipments!)
  end
end
