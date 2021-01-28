Spree::Payment.class_eval do
  state_machine initial: :checkout do
    event :refund do
      transition to: :refunded
    end

    event :partially_refund do
      transition to: :partially_refunded
    end
  end

  scope :refunded, -> { where(state: 'refunded') }
  scope :partially_refunded, -> { where(state: 'partially_refunded') }
  scope :full_or_partially_refunded, -> { where(state: ['refunded', 'partially_refunded']) }
  scope :not_refunded, -> { where.not(state: ['refunded', 'partially_refunded']) }
end
