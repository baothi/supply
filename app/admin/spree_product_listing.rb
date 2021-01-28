ActiveAdmin.register Spree::ProductListing do
  # config.filters = false

  menu false # label: 'Listings', parent: 'Product'

  # filter :retailer_id, label: 'Retailer ID'
  # filter :product_id, label: 'Product ID'
  # filter :id
  # filter :shopify_identifier, label: 'Shopify Identifier', as: :string
  # filter :product_id_equals, as: :number
  filter :product_id
  filter :shopify_identifier, label: 'Listing Shopify Identifier', as: :string

  index download_links: false, pagination_total: false do
    selectable_column

    column :id
    column :retailer
    column :supplier
    column :product
    column 'Product ID', &:product_id
    column :shopify_identifier

    actions
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :product
      input :retailer
      input :style_identifier
      input :shopify_identifier
      input :internal_identifier
    end

    actions
  end
end
