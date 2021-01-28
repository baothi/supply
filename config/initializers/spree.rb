# Comments were removed. High level summary is that, commenting out a setting doesn't reset it
# You must explictly reset/change its value.

Spree.config do |config|
  # Example:
  # Uncomment to stop tracking inventory levels in the application
  # config.track_inventory_levels = false
  config.logo = 'hingeto-white-logo.png'
  config.admin_interface_logo = 'hingeto-white-logo.png'
end

Spree::Auth::Config[:confirmable] ||= true

Spree.user_class = 'Spree::User'

Rails.application.config.spree.stock_splitters = [Spree::Stock::Splitter::CustomSplitter]
