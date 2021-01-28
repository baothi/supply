module Spree::Orders::StatusStateMachine
  extend ActiveSupport::Concern
  included do
    # When retailers pay for products we,
    # 1. Check if there's quantity available
    # 2. Make Payment
    # 3. Send Order To Shopify
    # 4. Complete
    aasm column: 'shopify_processing_status', whiny_persistence: true do
      state :not_initiated, initial: true
      state :scheduled
      state :country_check
      state :cost_check
      state :quantity_check
      state :payment_remittance
      state :order_remittance
      state :paused
      state :error
      state :successfully_sent_order

      event :reset_remittance do
        transitions to: :not_initiated
      end

      event :schedule_remittance do
        transitions to: :scheduled
      end

      event :check_country do
        transitions to: :country_check
      end

      event :check_costs do
        transitions to: :cost_check
      end

      event :check_quantity do
        transitions from: %i(cost_check),
                    to: :quantity_check
      end

      event :remit_payment do
        transitions from: %i(quantity_check),
                    to: :payment_remittance
      end

      event :remit_order do
        transitions from: %i(payment_remittance),
                    to: :order_remittance
      end

      event :raise_issue do
        transitions to: :error
      end

      event :pause_remittance do
        transitions from: %i(scheduled cost_check country_check quantity_check payment_remittance
                             order_remittance),
                    to: :paused
      end

      event :complete_remittance do
        transitions from: %i(order_remittance),
                    to: :successfully_sent_order
      end
    end
  end
end
