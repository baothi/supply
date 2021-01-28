module Spree::Suppliers::LicenseOptionManagement
  extend ActiveSupport::Concern

  included do
    has_many :supplier_license_options
  end

  # Helper to set the time we last run the methods in this concern
  def set_last_updated_licenses_at_to_now!
    self.update_column(:last_updated_licenses_at, DateTime.now)
  end
end
