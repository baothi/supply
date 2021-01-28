module PaymentsHelper
  def get_all_stripe_plan
    StripePlan.active.order(:amount)
  end
end
