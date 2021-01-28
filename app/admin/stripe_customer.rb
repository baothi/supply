ActiveAdmin.register StripeCustomer do
  config.filters = false

  menu parent: 'Stripe', label: 'Customers'

  index download_links: false, pagination_total: false do
    selectable_column

    column :customer_identifier
    column :strippable
    column :strippable_type
    column :account_balance
    column :description
    column :email

    actions
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :currency
      input :default_source
      input :delinquent
      input :description
      input :email
    end
  end
end
