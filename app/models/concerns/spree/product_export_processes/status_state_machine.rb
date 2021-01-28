module Spree::ProductExportProcesses::StatusStateMachine
  extend ActiveSupport::Concern
  included do
    aasm column: 'status', whiny_persistence: true do
      state :scheduled, initial: true
      state :in_progress
      state :paused
      state :cancelled
      state :error
      state :variants_export
      state :images_export
      state :completed

      after_all_transitions :log_status_change

      event :begin_export do
        transitions to: :in_progress
      end

      event :raise_issue do
        transitions to: :error
      end

      event :reschedule_export do
        transitions to: :scheduled
      end

      event :cancel_export do
        transitions to: :cancelled
      end

      event :queue_images do
        transitions from: %i(in_progress),
                    to: :images_export
      end

      event :export_variants do
        transitions from: %i(images_export),
                    to: :variants_export
      end

      event :pause_export do
        transitions from: %i(scheduled in_progress),
                    to: :paused
      end

      event :complete_export do
        transitions from: %i(scheduled in_progress paused variants_export),
                    to: :completed
      end

      event :restart do
        transitions from: :completed, to: :in_progress
      end
    end
  end

  def log_status_change
    val = "changing from #{aasm.from_state} to #{aasm.to_state} (event: #{aasm.current_event})"
    log_activity!(val)
  end
end
