ActiveAdmin.register Spree::InventoryUnit do
  config.filters = false

  menu parent: 'Orders'

  index download_links: false, pagination_total: false do
    selectable_column
    column :order
    column :line_item
    column :variant
    column :shipment
    column :state

    actions
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :state
      input :variant_id
      input :order_id
      input :pending
      input :line_item_id
    end

    actions
  end
end
