Spree::OrderUpdater.class_eval do
  def update_shipments
    shipments.each do |shipment|
      next unless shipment.persisted?
      next if shipment.cancelled_at.present?

      shipment.update!(order)
      shipment.refresh_rates
      shipment.update_amounts
    end
  end
end
