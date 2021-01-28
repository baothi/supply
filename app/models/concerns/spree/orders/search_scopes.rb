module Spree::Orders::SearchScopes
  extend ActiveSupport::Concern

  included do
    scope :fulfilled, -> { complete.where(shipment_state: 'shipped') }
    scope :unfulfilled, -> { complete.where(shipment_state: ['ready', 'pending']) }

    # scope :paid, -> { complete.where(payment_state: 'paid') }
    # scope :unpaid, -> { complete.where(payment_state: ['balance_due', 'credit_owned', 'failed']) }
    # scope :unpaid, -> { complete.where(payment_state: ['balance_due', 'credit_owned', 'failed']) }

    scope :filter, ->(team, status, q) do
      team.orders.filter_by_status(status).filter_by_attributes(q)
    end

    scope :filter_by_status, ->(status) do
      return unless status.present?

      statuses = %w(paid unpaid fulfilled unfulfilled risky late due_soon
                    due_in_24_hours international partially_fulfilled cancelled)
      if statuses.include? status
        send(status)
      end
    end

    scope :filter_by_attributes, ->(q) do
      return unless q.present?

      where('lower(searchable_attributes) LIKE ?', "%#{q.downcase}%")
    end

    scope :unpaid, -> { where.not(id: paid) }

    scope :paid, -> { joins(:payments) }

    scope :archived, -> { unscoped.where.not(archived_at: nil) }

    scope :unarchived, -> { where(archived_at: nil) }
    # This may be confusing due to the above. However, since we do not
    # fully leverage Spree's internal mechanism for representing payments
    # we know that some items that are fully paid for (in our eyes)
    # sometimes have balance_due, credit_owed as their status
    # and that's all we care about
    scope :has_payment, -> {
      complete.where(payment_state: ['balance_due', 'credit_owned', 'paid'])
    }

    scope :remindable_unpaid_orders, -> {
      complete.unpaid.where('spree_orders.payment_reminder_count < ?', 3)
    }

    scope :non_sample_orders, -> { complete.where(source: ['', nil]) }
    scope :sample_orders, -> { complete.where(source: 'app') }
    # scope :sample_orders_with_free_shipping, -> {
    #   complete.has_payment.where(source: 'app',
    #                              total_shipment_cost: 0)
    # }
    scope :sample_orders_with_free_shipping, -> {
      complete.where(source: 'app',
                     total_shipment_cost: 0)
    }

    scope :is_reported, -> {
      joins(:order_issue_report)
    }

    scope :from_completed_at, ->(from) {
      where('spree_orders.completed_at >= :from', from: from)
    }
    scope :to_completed_at, ->(to) {
      where('spree_orders.completed_at <= :to', to: to)
    }

    scope :completed_last_month, -> {
      beginning_of_last_month =
        DateTime.now.last_month.beginning_of_month
      end_of_last_month =
        DateTime.now.last_month.end_of_month
      from_completed_at(beginning_of_last_month).to_completed_at(end_of_last_month)
    }

    scope :completed_this_month, -> {
      beginning_of_month =
        DateTime.now.beginning_of_month
      end_of_month =
        DateTime.now.end_of_month
      from_completed_at(beginning_of_month).to_completed_at(end_of_month)
    }

    scope :from_created, ->(from) {
      where('spree_orders.created_at >= :from', from: from)
    }

    scope :to_created, ->(to) {
      where('spree_orders.created_at <= :to', to: to)
    }

    scope :created_last_month, -> {
      beginning_of_last_month =
        DateTime.now.last_month.beginning_of_month
      end_of_last_month =
        DateTime.now.last_month.end_of_month
      from_created(beginning_of_last_month).to_created(end_of_last_month)
    }

    scope :created_this_month, -> {
      beginning_of_period =
        DateTime.now.beginning_of_month
      end_of_period =
        DateTime.now.end_of_month
      from_created(beginning_of_period).to_created(end_of_period)
    }

    scope :created_in_last_30_days, -> {
      beginning_of_period =
        DateTime.now - 30.days
      end_of_period =
        DateTime.now
      from_created(beginning_of_period).to_created(end_of_period)
    }

    scope :exclude_retailer, ->(retailer_id) {
      where.not(retailer_id: retailer_id)
    }

    scope :exclude_first_retailer, ->  {
      exclude_retailer(1)
    }

    scope :amazon_order, -> {
      q = "customer_email iLIKE '%amazon%'"
      where(q)
    }

    scope :ebay_order, -> {
      q = "customer_email iLIKE '%ebay%'"
      where(q)
    }

    scope :auto_paid, -> {
      complete.where.not(auto_paid_at: nil)
    }

    scope :auto_paid_not_notified, -> {
      auto_paid.where(auto_paid_retailer_notified_at: nil)
    }

    scope :late, -> {
      where('spree_orders.must_fulfill_by < ?', DateTime.now).
        where.not(id: shipped_or_partially_shipped_orders).
        where.not(id: cancelled)
    }
    scope :due_soon, -> {
                       where('spree_orders.must_fulfill_by <= ?', DateTime.now + 3.days).
                         where('spree_orders.must_fulfill_by >= ?', DateTime.now).
                         where.not(id: shipped_or_partially_shipped_orders).
                         where.not(id: cancelled)
                     }
    scope :due_in_24_hours, -> {
                              where('spree_orders.must_fulfill_by <= ?', DateTime.now + 24.hours).
                                where('spree_orders.must_fulfill_by >= ?', DateTime.now).
                                where.not(id: shipped_or_partially_shipped_orders).
                                where.not(id: cancelled)
                            }
    scope :shipped_orders, -> {
                             where('spree_orders.shipment_state = ? ', 'shipped')
                           }
    scope :shipped_or_partially_shipped_orders, -> {
                                                  shipped_orders.or(partially_fulfilled)
                                                }
    scope :cancelled, -> {
                        where('spree_orders.shipment_state = ? ', 'canceled')
                      }
    scope :partially_fulfilled, -> {
                                  where('spree_orders.shipment_state = ? ', 'partial')
                                }
    scope :risky, -> {
      # where(risk_recommendation: ['cancel', 'investigate'])
      joins(:order_risks).
        where(spree_order_risks: { recommendation: ['cancel', 'investigate'] }).uniq
    }
    scope :international, -> {
      joins(ship_address: [:country]).
        where('spree_countries.iso != ?', 'US')
    }

    # def self.default_scope
    #   where(archived_at: nil)
    # end
  end
end
