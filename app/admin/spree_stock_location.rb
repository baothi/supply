ActiveAdmin.register Spree::StockLocation do
  config.filters = false

  # menu label: 'Location', parent: 'Stock'
  menu false

  index download_links: false, pagination_total: false do
    selectable_column

    column :name
    column :country
    column :state
    column :city
    column :address1
    column :zipcode
    column :phone

    actions
  end
end
