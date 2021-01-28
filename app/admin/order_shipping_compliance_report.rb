ActiveAdmin.register_page 'Order Shipping Compliance Report' do
  menu label: 'Order Shipping Compliance Report', parent: 'Orders'
  content do
    render partial: 'admin/orders/shipping_compliance_report'
  end
end
