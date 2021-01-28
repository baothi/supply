module Spree::LongRunningJobs::StatusStateMachine
  extend ActiveSupport::Concern
  included do
    aasm column: 'status', whiny_persistence: true do
      state :scheduled, initial: true
      state :in_progress
      state :paused
      state :cancelled
      state :error
      state :completed

      event :begin_job do
        transitions to: :in_progress
      end

      event :raise_issue, after: :after_job_fail_callback do
        transitions to: :error
      end

      event :reschedule_job do
        transitions to: :scheduled
      end

      event :cancel_job do
        transitions from: %i(scheduled in_progress paused),
                    to: :cancelled
      end

      event :pause_job do
        transitions from: %i(scheduled in_progress),
                    to: :paused
      end

      event :complete_job do
        transitions from: %i(scheduled in_progress paused),
                    to: :completed
      end
    end
  end

  # TODO: This probably shouldn't belong / live here
  def after_job_fail_callback
    return unless job_type == 'orders_export' && setting_auto_paid

    notify_retailer_of_auto_export_failure
  end

  def notify_retailer_of_auto_export_failure
    JobsMailer.retailer_auto_pay_failure(self.id)
  end
end
