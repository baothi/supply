module EnsureStrippable
  extend ActiveSupport::Concern

  included do
    before_action :ensure_supplier_is_strippable
  end

  private

  def ensure_supplier_is_strippable
    return if current_retailer.stripe_customer

    StripeService.create_stripe_customer(current_retailer)
    current_retailer.reload
  end
end
