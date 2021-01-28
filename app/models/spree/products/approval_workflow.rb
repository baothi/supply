module Spree::Products::ApprovalWorkflow
  extend ActiveSupport::Concern

  included do
    aasm whiny_persistence: true, column: :submission_state do
      state :pending_review, initial: true
      state :approved
      state :declined
      state :in_review
      state :requires_additional_information

      event :start_review do
        transitions from: :pending_review, to: :in_review
      end

      event :reject do
        transitions to: :declined
      end

      event :request_additional_information do
        transitions from: :in_review, to: :requires_additional_information
      end

      event :approve do
        transitions from: :in_review, to: :approved, guard: :eligible_for_approval?
      end

      event :skip_middle_steps_and_approve do
        transitions to: :approved, guard: :eligible_for_approval?
      end

      event :skip_middle_steps_and_reject do
        transitions to: :declined
      end
    end
  end

  class_methods do
    # Since the initial state isn't actually set / saved in the db, we can't
    # search records by it.
    def assignable_workflow_states
      Spree::Product.aasm.states.reject { |x| x.name == :pending_review }
    end
  end
end
