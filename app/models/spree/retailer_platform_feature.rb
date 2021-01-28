module Spree
  class RetailerPlatformFeature < ApplicationRecord
    # Settings Capabilities
    include Settings::Settingable

    # Inventory
    setting :inventory_real_time_updates, :boolean, default: false
    setting :inventory_hourly_updates, :boolean, default: false
    setting :inventory_daily_updates, :boolean, default: true
    setting :inventory_weekly_updates, :boolean, default: false

    # Platform Support
    setting :integrations_shopify, :boolean, default: true
    setting :integrations_sftp, :boolean, default: true
    setting :integrations_dsco, :boolean, default: true
    setting :integrations_magento, :boolean, default: true
    setting :integrations_zapier, :boolean, default: true

    # Products
    setting :num_live_products, :integer, default: 10

    # Shopify
    setting :shopify_send_metafields_on_product, :boolean, default: false

    # Suppliers
    setting :suppliers_can_view_all, :boolean, default: false
    setting :suppliers_can_request_connection, :boolean, default: false

    # Margin to retailer
    setting :products_default_margin, :integer, default: 40
    setting :products_can_access_general_catalogue, :boolean, default: true
    setting :products_can_access_exclusive_catalogue, :boolean, default: false

    # Orders
    setting :orders_num_monthly, :integer, default: 500
    setting :orders_allow_samples, :boolean, default: false

    # Packing Slip
    setting :packing_slip_custom, :boolean, default: false

    # Other Custom
    setting :custom_vendor_documents, :boolean, default: false
    setting :custom_wholesale_costs, :boolean, default: false

    # Support
    setting :support_enable_email, :boolean, default: true
    setting :support_email_address, :string, default: 'support@hingeto.com'
    setting :support_enable_chat, :boolean, default: false

    # Inventory Concierge
    setting :allow_inventory_concierge, :boolean, default: false

    # Default
    setting :default_platform_credits, :integer, default: 200
  end
end
