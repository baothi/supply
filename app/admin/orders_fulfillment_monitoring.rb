ActiveAdmin.register_page 'Orders Fulfillment Monitoring' do
  menu label: 'Orders Fulfillment Monitoring', parent: 'Orders'
  content do
    render partial: 'admin/orders/fulfillment_monitoring'
  end
end
