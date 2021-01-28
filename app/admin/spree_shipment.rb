ActiveAdmin.register Spree::Shipment do
  config.filters = false

  menu parent: 'Shipment', label: 'Shipments'

  controller do
    def find_resource
      scoped_collection.where(number: params[:id]).first!
    end
  end

  index download_links: false, pagination_total: false  do
    selectable_column

    column :tracking
    column :order
    column :number
    column :cost
    column :address
    column :state

    actions
  end
end
