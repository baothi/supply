FactoryBot.define do
  factory :spree_shipping_zone_eligibility, class: 'Spree::ShippingZoneEligibility' do
    supplier factory: :spree_supplier
    zone factory: :zone
  end
end
