ActiveAdmin.register Spree::ShippingRate do
  config.filters = false

  menu parent: 'Shipment', label: 'Rates'

  index download_links: false, pagination_total: false do
    selectable_column

    column :shipment
    column :shipping_method
    column :selected
    column :cost
    column :tax_rate

    actions
  end
end
