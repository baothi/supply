ActiveAdmin.register Spree::StockItem do
  config.filters = false

  # menu label: 'Stock Items', parent: 'Stock'
  menu false

  index download_links: false, pagination_total: false do
    selectable_column

    column :stock_location
    column :variant
    column :count_on_hand
    column :backorderable

    actions
  end
end
