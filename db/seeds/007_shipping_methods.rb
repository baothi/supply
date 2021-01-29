# Courier Services
shipping_methods = [
    {
        courier_code: 'FEDEX',
        service_name: 'International Priority',
        service_code: 'FEIP',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'International Economy',
        service_code: 'FEIE',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'SameDay',
        service_code: 'FESD',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'SameDay City',
        service_code: 'FSDC',
        active: false
    },
    {
        courier_code: 'FEDEX',
        service_name: 'First Overnight',
        service_code: 'FEFO',
        active: false
    },
    {
        courier_code: 'FEDEX',
        service_name: 'Priority Overnight',
        service_code: 'FEPO',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'Standard Overnight',
        service_code: 'FESO',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: '2Day A.M.',
        service_code: 'F2DA',
        active: false
    },
    {
        courier_code: 'FEDEX',
        service_name: '2Day',
        service_code: 'FE2D',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'Express Saver',
        service_code: 'FEES',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'Ground',
        service_code: 'FEG',
        active: true
    },
    {
        courier_code: 'FEDEX',
        service_name: 'Home Delivery',
        service_code: 'FEHD',
        active: false
    },
    {
        courier_code: 'FEDEX',
        service_name: 'SmartPost',
        service_code: 'FESP',
        active: true
    },
    {
        courier_code: 'USPS',
        service_name: 'Priority Mail Express',
        service_code: 'USPE',
        active: true
    },
    {
        courier_code: 'USPS',
        service_name: 'Priority Mail',
        service_code: 'USPM',
        active: true
    },
    {
        courier_code: 'USPS',
        service_name: 'First-Class Mail',
        service_code: 'USFC',
        active: true
    },
    {
        courier_code: 'USPS',
        service_name: 'Ground',
        service_code: 'USG',
        active: true
    }, # Now UPS
    {
        courier_code: 'UPS',
        service_name: 'Next Day Air',
        service_code: 'UPNDA',
        active: true
    },
    {
        courier_code: 'UPS',
        service_name: '2nd Day Air',
        service_code: 'UP2DA',
        active: true
    },
    {
        courier_code: 'UPS',
        service_name: 'Ground',
        service_code: 'UPG',
        active: true
    },
    {
        courier_code: 'UPS',
        service_name: '3 Day Select',
        service_code: 'UP3DS',
        active: true
    },
    {
        courier_code: 'UPS',
        service_name: 'Standard',
        service_code: 'UPSS',
        active: true
    }, # General
    {
        courier_code: 'Generic',
        service_name: 'Three Day',
        service_code: 'G3D',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Ground',
        service_code: 'GGR',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Express Saver',
        service_code: 'GXS',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'International',
        service_code: 'GIX',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Next Day',
        service_code: 'GND',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Same Day',
        service_code: 'GSD',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Second Day',
        service_code: 'G2D',
        active: true
    },
    {
        courier_code: 'Generic',
        service_name: 'Priority',
        service_code: 'GPR',
        active: true
    }
]

# Other codes will be: USPS, UPS, DHL
us_only = Spree::Zone.find_by!(
  name: 'United States',
  kind: 'country'
)

shipping_methods.each do |shipping_method|
  Spree::ShippingMethod.find_or_create_by!(code: shipping_method[:service_code]) do |method|
    courier = Spree::Courier.find_by_code!(shipping_method[:courier_code])

    puts "Courier: #{courier.name}"

    method.courier_id = courier.id
    method.code = shipping_method[:service_code]
    method.service_code = shipping_method[:service_code]
    method.name = "(#{courier.name}) #{shipping_method[:service_name]}"
    method.service_name = shipping_method[:service_name]
    method.active = shipping_method[:active]
    calculator = Spree::Calculator::Shipping::FlatRate.new
    calculator.preferred_amount = 0
    # calculator.currency = "USD"
    method.calculator = calculator

    default_category = Spree::ShippingCategory.first
    default_category ||= Spree::ShippingCategory.create!(name: 'Default')

    method.shipping_categories << default_category
    method.zones << us_only
  end
end
