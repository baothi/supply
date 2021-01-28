class Spree::SupplierPlatformFeature < ApplicationRecord
  # Settings Capabilities
  include Settings::Settingable

  # Products
  setting :num_team_members, :integer, default: 2

  # Support
  setting :support_enable_email, :boolean, default: true
  setting :support_email_address, :string, default: 'support@hingeto.com'
  setting :support_enable_chat, :boolean, default: false
end
