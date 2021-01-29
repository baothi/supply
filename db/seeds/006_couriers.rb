# Courier Services
services = [
    {
        code: 'FEDEX',
        name: 'FedEx',
        website: 'https://www.fedex.com',
        active: true
    },
    {
        code: 'USPS',
        name: 'USPS',
        website: 'https://www.usps.com',
        active: true
    },
    {
        code: 'UPS',
        name: 'UPS',
        website: 'https://www.ups.com',
        active: true
    },
    {
        code: 'Generic',
        name: 'Generic',
        website: 'https://www.hingeto.com',
        active: true
    }
]
# Other codes will be: USPS, UPS, DHL

services.each do |service|
  Spree::Courier.find_or_create_by(code: service[:code]) do |courier|
    courier.name = service[:name]
    courier.website = service[:website]
    courier.active = service[:active]
  end
end
