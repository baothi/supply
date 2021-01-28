ActiveAdmin.register Spree::LineItem, as: 'FinanceReport' do
  config.sort_order = 'order_id_asc'

  filter :created_at, as: :date_range, label: 'Created Between'
  filter :retailer, input_html: { id: 'selling-authority-retailer-id', type: 'hidden' }
  filter :supplier, input_html: { id: 'selling-authority-supplier-id', type: 'hidden' }
  filter :order_number_equals, label: 'Order Number'

  actions :index

  menu parent: 'Orders'

  controller do
    def scoped_collection
      super.includes :retailer, :supplier, :product, :variant,
                     inventory_units: [:shipment], order: %i(shipments payments)
    end
  end

  action_item(:download_for_email, only: :index) do
    params.permit!
    link_to 'Download For Email', download_for_email_admin_finance_reports_path(q: params[:q].to_h),
            method: :post
  end

  collection_action :download_for_email, method: :post do
    params.permit!
    Spree::LineItem.download_finance_report(params, current_spree_user.id)
    flash[:notice] = "CSV Export have started in the background. \
          You'll will get an email containing your attachment shortly!"
    redirect_to admin_dashboard_path
  end

  index download_links: false, pagination_total: true do
    h1 'Some columns are hidde but they will appear in the report when you download it.'
    column 'Retailer Order Name', :order_retailer_shopify_name
    column 'Supplier Order Name', :order_supplier_shopify_order_name
    column 'Date Created On Shopify', :order_completed_at
    column 'Date Created On Hingeto', :created_at
    column 'Product Title', :product_title
    column 'Supplier', :supplier_name
    column 'Retailer', :retailer_name
    column 'Shipment State', :shipment_state
    column 'Ship Date', :ship_date
    column '(Broken) Ship Date', :broken_ship_date
    column 'Payment State', :order_payment_state_display
    column 'Ordered Quantity', :quantity
    column :wholesale_cost do |li|
      span class: 'money' do
        li.wholesale_cost
      end
    end
    column :total_sales do |li|
      span class: 'money' do
        li.total_sales
      end
    end
    column :shipping do |li|
      span class: 'money' do
        li.line_item_shipping_cost
      end
    end
    column :supplier_payment_amount do |li|
      span class: 'money' do
        li.supplier_payment_amount
      end
    end
  end
end
